module util.misc;

import core.sys.windows.windows;
import core.sys.windows.windef;
import std.conv : to;
import core.stdc.string;
import util;
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

@nogc void write(T)(Address address, T value)
{
    if (address < maxAddr && address > minAddr && address % 4uL == 0uL)
    {
        *cast(T*) address = value;
    }
}

void rvaWrite(T)(Address address, T value)
{
    write!T(cast(Address)GetModuleHandle("rs2client.exe") + address, value);
}

extern(Windows) T vTableInvocation(T)(
    ulong* thisptr,
    int fnIndex,
    long* arg
)
{
    ulong* vTable = *cast(ulong**) thisptr;
    alias FuncPtr = extern(Windows) T function(void*, long*);
    FuncPtr func = cast(FuncPtr)(vTable[fnIndex]);
    return func(thisptr, arg);
}

mixin template fn(string name, ulong loc, T...)
{
    mixin("alias ", name, "_t = extern(Windows) ulong function(T);");
    mixin(name, "_t ", name, " = cast(", name, "_t)(GetModuleHandle(NULL) + loc);");
}