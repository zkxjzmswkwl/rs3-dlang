module kronos.hook;

import core.stdc.stdint;
import core.sys.windows.windows;
import std.stdio;
import std.conv : to;
import std.algorithm.comparison;
import core.stdc.string;

///
/// https://code.dlang.org/packages/capstone-d
/// Slight modification, see https://github.com/zkxjzmswkwl/capstone-d
///
import capstone;
import slf4d;
import util;

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
    ///
    /// For debugging/logging.
    ///
    private string name;
    ///
    /// Target function RVA.
    ///
    private Address location;
    /// 
    /// Location of our mapped function.
    ///
    private Address jmpTo;
    /// 
    /// Capstone instance
    ///
    private Capstone cs;

    this(Address location, string name, bool sameModule = true)
    {
        if (sameModule)
            this.location = cast(ulong) GetModuleHandle("rs2client.exe") + location;
        else
            this.location = location;

        this.cs = create(Arch.x86, ModeFlags(Mode.bit64));
        this.name = name;
    }

    extern (Windows)
    public void place(void* ourFunction, void** trampolinePtr)
    {
        try
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
            /*
            Since we only have space for a 32-bit relative jmp (0xE9), we need to calculate the relative address
            from the start of the hooked function (this.location) to the point in the relay function
            in which we 64-bit absolute jmp to the body of our hook.

            The relay function looks like this, roughly:
                mov    rcx,[rcx+08]                    ; Stolen bytes
                mov    r8,rdx                          ; Stolen bytes
                mov    r10,rs2client.exe+117555
                jmp    r10                             ; jmp back to just after our 32-bit jmp in the original func location.
                mov    r10,DeOppressoLiber.dll+13A2    
                jmp    r10                             ; jmp to the point in our jmp table where we jmp to the body of our hook. (see below)

            The jmp table looks like this:
                jmp    DeOpressoLiber.dll+16BA0
                jmp    DeOpressoLiber.dll+16FDBC
                jmp    DeOpressoLiber.dll+15F874
                ...etc
            
            It's just a big table filled with jmps to locations in our module.
            */
            int32_t relativeAddress = cast(int32_t)(cast(uintptr_t) relayFuncMemory - (cast(uintptr_t) location + 5));
            memcpy(&jmpIsns32[1], &relativeAddress, 4);
            memcpy(cast(void*) location, &jmpIsns32[0], 5);

            // put da condom back on
            VirtualProtect(cast(void*) location, 1024, previousProtection, null);

            infoF!"Hook(%s) at %016X"(this.name, location);
        }
        catch (Exception ex)
        {
            writeln(ex.msg);
        }
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
                relocateInstruction(inst, stolenByteMem);
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

        return cast(uint)(cast(void*) absTableMem - trampDest);
    }

    private void rewriteCallInstruction(X86Instruction* ins, ubyte* instrPtr, ubyte* absTableEntry)
    {
        ubyte distToJumpTable = cast(ubyte)(absTableEntry - (instrPtr + ins.bytes.length));

        ubyte[] jmpBytes = [0xEB, distToJumpTable];
        for (uint i = 0; i < ins.bytes.length; ++i)
            ins.setByte(i, 0x90);

        for (uint i = 0; i < jmpBytes.length; ++i)
            ins.setByte(i, jmpBytes[i]);
    }

    private void rewriteJumpInstruction(X86Instruction* ins, ubyte* instrPtr, ubyte* absTableEntry)
    {
        ubyte distToJumpTable = cast(ubyte)(absTableEntry - (instrPtr + ins.bytes.length));
        ubyte insByteSize = ins.bytes[0] == 0x0F ? 2 : 1;
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

        uint byteCount = 0;
        uint stolenIsnCount = 0;
        for (uint i = 0; i < count; ++i)
        {
            auto inst = disasmIsns[i];
            byteCount += inst.bytes.length;
            stolenIsnCount++;
            if (byteCount >= 5)
                break;
        }

        writeNops(func, byteCount);
        this.cs.detail = false;

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
        memcpy(dstMem, &callAsmBytes[0], callAsmBytes.sizeof);
        dstMem += callAsmBytes.sizeof;

        // Might be fucked, the second cast to ubyte seems off.
        ubyte[2] jmpBytes = [
            cast(ubyte) 0xEB,
            cast(ubyte)(jumpBackMem - (absTableMem +  /*jmpBytes.sizeof*/ 2))
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
        memcpy(jmpMem, &jmpIsns[0], jmpIsns.sizeof);
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

    private ubyte[] readBytes(T)(T address, size_t size)
    {
        ubyte* bufferLoc = cast(ubyte*) address;
        auto ret = bufferLoc[0 .. size];
        return ret;
    }

    private void writeNops(T)(T address, size_t size)
    {
        memset(address, 0x90, size);
    }

    private bool isRelativeIsn(X86Instruction* inst)
    {
        const X86Detail detail = inst.detail;
        if (detail is null)
        {
            return false;
        }

        foreach (op; detail.operands[0 .. detail.operands.length])
        {
            if (op.type == X86OpType.mem && op.mem.base.id == X86RegisterId.rip)
            {
                return true;
            }
        }

        return false;
    }

    private bool isRelativeCall(X86Instruction* inst)
    {
        return inst.bytes[0] == 0xE8 && inst.id == X86InstructionId.call;
    }

    private bool isRelativeJump(X86Instruction* inst)
    {
        bool isAnyJmp = inst.id >= X86InstructionId.jae && inst.id <= X86InstructionId.js;
        bool isJmp = inst.id == X86InstructionId.jmp;
        bool startsWithEBorE9 = inst.bytes[0] == 0xEB || inst.bytes[0] == 0xE9;
        return isJmp ? startsWithEBorE9 : isAnyJmp;
    }

    private T getDisplacement(T)(X86Instruction* inst, ubyte offset)
    {
        T disp;
        memcpy(&disp, &inst.bytes[offset], T.sizeof);
        return disp;
    }

    private void relocateInstruction(X86Instruction* inst, void* destination)
    {
        const X86Detail detail = inst.detail;
        if (detail is null)
        {
            return;
        }

        ubyte offset = detail.encoding.dispOffset;
        switch (offset)
        {
        case 1:
            byte disp = getDisplacement!byte(inst, offset);
            disp -= cast(ulong)(destination) - inst.address;
            memcpy(cast(void*)&inst.bytes[offset], &disp, byte.sizeof);
            break;
        case 2:
            short disp = getDisplacement!short(inst, offset);
            disp -= cast(ulong)(destination) - inst.address;
            memcpy(cast(void*)&inst.bytes[offset], &disp, short.sizeof);
            break;
        case 4:
            int disp = getDisplacement!int(inst, offset);
            disp -= cast(ulong)(destination) - inst.address;
            memcpy(cast(void*)&inst.bytes[offset], &disp, int.sizeof);
            break;
        default:
            break;
        }
    }
}
