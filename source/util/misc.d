module util.misc;

import std.conv : to;
import core.stdc.string;
import util.types;
import capstone;
import capstone.x86;
import capstone.detail;

ubyte[] readBytes(T)(T address, size_t size)
{
    ubyte* bufferLoc = cast(ubyte*) address;
    auto ret = bufferLoc[0 .. size];
    return ret;
}

void writeNops(T)(T address, size_t size)
{
    memset(address, 0x90, size);
}

bool isRelativeIsn(X86Instruction* inst)
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

bool isRelativeCall(X86Instruction* inst)
{
    return inst.bytes[0] == 0xE8 && inst.id == X86InstructionId.call;
}

bool isRelativeJump(X86Instruction* inst)
{
    bool isAnyJmp = inst.id >= X86InstructionId.jae && inst.id <= X86InstructionId.js;
    bool isJmp = inst.id == X86InstructionId.jmp;
    bool startsWithEBorE9 = inst.bytes[0] == 0xEB || inst.bytes[0] == 0xE9;
    return isJmp ? startsWithEBorE9 : isAnyJmp;
}

T getDisplacement(T)(X86Instruction* inst, ubyte offset)
{
    T disp;
    memcpy(&disp, &inst.bytes[offset], T.sizeof);
    return disp;
}

void relocateInstruction(Capstone cs, X86Instruction* inst, void* destination)
{
    const X86Detail detail = inst.detail;
    if (detail is null)
    {
        return;
    }

    ubyte offset = detail.encoding.dispOffset;
    ulong displacement = inst.bytes[offset];
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

struct Fn(T...)
{
    T args_;
    Address loc_;

    this(Address loc, T args)
    {
        args_ = args;
        loc_ = loc;
    }

    extern (Windows) void call()
    {
        alias FnProto = extern (Windows) void function(T);
        FnProto func = cast(FnProto) loc_;
        func(args_);
    }
}

Fn!(Args) fnCall(Args...)(Address loc, Args args)
{
    auto fn = typeof(return)(loc, args);
    fn.call();
    return fn;
}

auto maxAddr = 0x7FFFFFFF0000uL;
auto minAddr = 0x100000uL;

@nogc T read(T)(Address address)
{
    if (address < maxAddr && address > minAddr && address % 4uL == 0uL)
    {
        try
            return *cast(T*) address;
        catch (Exception e)
            return T.init;
    }
    return T.init;
}