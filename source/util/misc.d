module util.misc;

import std.conv : to;
import core.stdc.string;
import util.types;
import capstone;
import capstone.x86;
import capstone.detail;

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

extern(Windows) T vTableInvocation(T)(
    ulong* thisptr,       // rcx
    int fnIndex,   // Inc by sizeof ptr (0x8/0x4), *thisptr -> vTable data
    long* arg
)
{
    ulong* vTable = *cast(ulong**) thisptr;
    alias FuncPtr = extern(Windows) T function(void*, long*);
    FuncPtr func = cast(FuncPtr)(vTable[fnIndex]);
    return func(thisptr, arg);
}