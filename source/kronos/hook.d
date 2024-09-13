module kronos.hook;

import std.stdio;
import std.conv : to;
import core.sys.windows.windows;
import std.algorithm.comparison;
import core.stdc.string;
import util.types;
import util.misc;

///
/// https://code.dlang.org/packages/capstone-d
///
import capstone;

class Instructions
{
    X86Instruction* instructions;
    uint numIsns;
    uint numBytes;

    this(X86Instruction* instructions, uint numIsns, uint numBytes)
    {
        this.instructions = instructions;
        this.numIsns = numIsns;
        this.numBytes = numBytes;
    }
}

class Hook
{
    // For debugging/logging.
    private string name;

    ///
    /// Where we're placing the jmp.
    ///
    private Address location;
    /// 
    /// Location of our mapped function.
    ///
    private Address jmpTo;
    /// 
    /// Capstone pointer
    ///
    private Capstone* cs;

    this(Address location, Capstone* cs, string name)
    {
        this.location = location;
        this.cs = cs;
        this.name = name;
    }

    public void place(void* ourFunction, void** trampolinePtr)
    {
        DWORD previousProtection;
        // take da condom off
        VirtualProtect(cast(void*) location, 1024, PAGE_EXECUTE_READWRITE, &previousProtection);

        void* relayPage = this.writeRelayPage();
        uint trampolineSize = buildTrampoline(cast(void*) location, relayPage);
        *trampolinePtr = relayPage;

        void* relayFuncMemory = cast(char*) relayPage + trampolineSize;
        this.writeJmp(relayFuncMemory, ourFunction);

        ubyte[] jmpIsns32 = [0xE9, 0x0, 0x0, 0x0, 0x0];
        // this math is fucked but im too drunk to fix it 
        uint relativeAddress = cast(uint)(cast(uint) relayPage - cast(uint)(location + jmpIsns32.sizeof)) + 31;
        memcpy(&jmpIsns32[1], &relativeAddress, 4);
        memcpy(cast(void*) location, &jmpIsns32[0], 5);

        // put da condom back on
        VirtualProtect(cast(void*) location, 1024, previousProtection, null);
    }

    private uint buildTrampoline(void* func, void* trampDest)
    {
        Instructions stolenIsns = this.stealBytes(func);
        ubyte* stolenByteMem = cast(ubyte*) trampDest;
        ubyte* jumpBackMem = stolenByteMem + stolenIsns.numBytes;
        ubyte* absTableMem = jumpBackMem +  /*sizeof 64-bit mov & jmp*/ 13;

        for (uint i = 0; i < stolenIsns.numIsns; ++i)
        {
            X86Instruction* inst = &stolenIsns.instructions[i];
            auto instBytes = inst.bytes;
            auto instByteCount = instBytes.length;

            if (isRelativeIsn(inst))
            {
                relocateInstruction(this.cs, inst, stolenByteMem);
            }
            else if (isRelativeJump(inst))
            {
                uint aitSize = addJmpToAbsTable(inst, absTableMem);
                rewriteJumpInstruction(inst, stolenByteMem, absTableMem);
                absTableMem += aitSize;
            }
            else if (inst.id == X86InstructionId.call)
            {
                uint aitSize = addCallToAbsTable(inst, absTableMem, jumpBackMem);
                rewriteCallInstruction(inst, stolenByteMem, absTableMem);
                absTableMem += aitSize;
            }
            memcpy(cast(void*) stolenByteMem, cast(void*) instBytes, instByteCount);
            stolenByteMem += instByteCount;
        }

        writeJmp(jumpBackMem, cast(ubyte*) func + 5);
        writeln("Trampoline jumpBackMem: " ~ to!string(jumpBackMem));

        // absTableMem should be type `ubyte*` but D says no.
        // This might blow up.
        return cast(uint)(cast(ubyte*) absTableMem - cast(ubyte*) trampDest);
    }

    private void rewriteCallInstruction(X86Instruction* ins, ubyte* instrPtr, ubyte* absTableEntry)
    {
        ubyte distToJumpTable = cast(ubyte)(absTableEntry - (instrPtr + ins.bytes.length));

        ubyte[] jmpBytes = [0xEB, distToJumpTable];
        for (uint i = 0; i < ins.bytes.length; ++i)
        {
            ins.setByte(i, 0x90);
        }
        for (uint i = 0; i < jmpBytes.length; ++i)
        {
            ins.setByte(i, jmpBytes[i]);
        }
    }

    private void rewriteJumpInstruction(X86Instruction* ins, ubyte* instrPtr, ubyte* absTableEntry)
    {
        // This is also suspicious and might blow up. The cast seems wrong but D won't let me do what I want to do here.
        // Maybe the correct phrasing would be "I don't know how to do what I want to do here in D, yet", but who knows.
        ubyte distToJumpTable = cast(ubyte)(absTableEntry - (instrPtr + ins.bytes.length));
        ubyte insByteSize = ins.bytes[0] == 0x0F ? 2 : 1;
        // Same here.
        ubyte operandSize = cast(ubyte)(ins.bytes.length - insByteSize);

        switch (operandSize)
        {
        case 1:
            ins.setByte(insByteSize, distToJumpTable);
            break;
        case 2:
            ushort dist16 = distToJumpTable;
            memcpy(cast(void*) ins.bytes[insByteSize], &dist16, 2);
            break;
        case 4:
            int dist32 = distToJumpTable;
            memcpy(cast(void*) ins.bytes[insByteSize], &dist32, 4);
            break;
        default:
            break;
        }
    }

    private Instructions stealBytes(void* func)
    {
        this.cs.detail = true;

        size_t count;
        auto disasmIsns = this.cs.disasm(readBytes(func, 14), cast(ulong) func, 14);
        count = disasmIsns.length;
        writeln("Count of disasmIsns: " ~ to!string(count));

        uint byteCount = 0;
        uint stolenIsnCount = 0;
        for (uint i = 0; i < count; ++i)
        {
            auto inst = disasmIsns[i];
            byteCount += inst.bytes().length;
            stolenIsnCount++;
            if (byteCount >= 5)
                break;
        }

        writeNops(func, byteCount);
        writeln("Wrote nops @ " ~ to!string(func) ~ " for " ~ to!string(byteCount) ~ " bytes");
        // DebugBreak();

        return new Instructions(cast(X86Instruction*) disasmIsns, stolenIsnCount, byteCount);
    }

    private uint addJmpToAbsTable(X86Instruction* jmp, ubyte* absTableMem)
    {
        auto targetAddrStr = jmp.opStr;
        ulong targetAddr = to!ulong(targetAddrStr);
        writeJmp(absTableMem, cast(void*) targetAddr);
        return 13;
    }

    private uint addCallToAbsTable(X86Instruction* call, ubyte* absTableMem, ubyte* jumpBackMem)
    {
        auto targetAddrStr = call.opStr;
        ulong targetAddr = to!ulong(targetAddrStr);
        ubyte* dstMem = absTableMem;

        ubyte[] callAsmBytes = [
            0x49, 0xBA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA,
            0x41, 0xFF, 0xD2
        ];

        memcpy(&callAsmBytes[2], &targetAddr, targetAddr.sizeof);
        memcpy(dstMem, callAsmBytes.ptr, callAsmBytes.sizeof);
        dstMem += callAsmBytes.sizeof;

        // Might be fucked, the second cast to ubyte seems off.
        ubyte[2] jmpBytes = [
            cast(ubyte) 0xEB, cast(ubyte)(jumpBackMem - (absTableMem + 2))
        ];
        memcpy(dstMem, cast(void*) jmpBytes, jmpBytes.sizeof);

        return callAsmBytes.sizeof + jmpBytes.sizeof;
    }

    private void writeJmp(void* jmpMem, void* jmpLoc)
    {
        ubyte[] jmpIsns = [
            0x49, 0xBA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x41, 0xFF, 0xE2
        ];

        ulong ulJmpLoc = cast(ulong) jmpLoc;
        memcpy(&jmpIsns[2], &ulJmpLoc, ulJmpLoc.sizeof);
        memcpy(jmpMem, jmpIsns.ptr, jmpIsns.sizeof);
    }

    private void* writeRelayPage()
    {
        SYSTEM_INFO si;
        GetSystemInfo(&si);
        ulong PAGE_SIZE = si.dwPageSize;

        ulong start = (cast(ulong) location) & ~(PAGE_SIZE - 1);
        ulong minimum = min(start - 0x7FFFFF00, cast(ulong) si.lpMinimumApplicationAddress);
        ulong maximum = min(start + 0x7FFFFF00, cast(ulong) si.lpMaximumApplicationAddress);

        ulong sp = (start - (start % PAGE_SIZE));

        ulong poffset = 1;

        for (;;)
        {
            ulong boffset = poffset * PAGE_SIZE;
            ulong high = sp + boffset;
            ulong low = (sp > boffset) ? sp - boffset : 0;

            bool exit = high > maximum && low < minimum;
            if (high < maximum)
            {
                void* outLoc = VirtualAlloc(cast(void*) high, PAGE_SIZE, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
                if (outLoc != null)
                {
                    return outLoc;
                }
            }

            if (low > minimum)
            {
                void* outLoc = VirtualAlloc(cast(void*) low, PAGE_SIZE, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
                if (outLoc != null)
                {
                    return outLoc;
                }
            }

            poffset++;

            if (exit)
                break;
        }
        return null;
    }
}
