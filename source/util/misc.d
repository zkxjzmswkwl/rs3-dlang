module util.misc;

import core.sys.windows.windows;
import core.sys.windows.windef;
import core.stdc.string;
import std.conv : to;

import util;
import rdconstants;
import core.int128;

struct Fn(T...) {
    T args_;
    Address loc_;

    this(Address loc, T args) {
        args_ = args;
        loc_ = loc;
    }

    extern (Windows) void call() {
        alias FnProto = extern (Windows) void function(T);
        FnProto func = cast(FnProto) loc_;
        func(args_);
    }
}

Fn!(Args) fnCall(Args...)(Address loc, Args args) {
    auto fn = typeof(return)(loc, args);
    fn.call();
    return fn;
}

@nogc T read(T)(Address address) {
    try
        return *cast(T*) address;
    catch (Exception e)
        return T.init;
    return T.init;
}

@nogc void write(T)(Address address, T value) {
    if (address < MAX_ADDRESS && address > MIN_ADDRESS && address % 4uL == 0uL) {
        *cast(T*) address = value;
    }
}

void rvaWrite(T)(Address address, T value) {
    write!T(cast(Address)GetModuleHandle("rs2client.exe") + address, value);
}

T rvaRead(T)(Address address) {
    return read!T(cast(Address)GetModuleHandle("rs2client.exe") + address);
}

DWORD rvaAlterPageAccess(Address address, size_t size, DWORD newProtect) {
    auto base = cast(Address)GetModuleHandle("rs2client.exe");
    DWORD oldProtect;
    VirtualProtect(cast(void*)(base + address), size, newProtect, &oldProtect);
    return oldProtect;
}

Address resolvePtrChain(Address base, size_t[] offsets) {
    Address ptr = base;
    foreach (offset; offsets)   ptr = read!Address(ptr + offset);
    return ptr;
}

extern(Windows) T vTableInvocation(T)(
    ulong* thisptr,
    int fnIndex,
    long* arg
) {
    ulong* vTable = *cast(ulong**) thisptr;
    alias FuncPtr = extern(Windows) T function(void*, long*);
    FuncPtr func = cast(FuncPtr)(vTable[fnIndex]);
    return func(thisptr, arg);
}

mixin template fn(string name, ulong loc, T...) {
    mixin("alias ", name, "_t = extern(Windows) ulong function(T);");
    mixin(name, "_t ", name, " = cast(", name, "_t)(GetModuleHandle(NULL) + loc);");
}

Address resolveFunction(string moduleName, string exportedFunction) {
    auto moduleHandle = GetModuleHandle(cast(const(wchar)*)moduleName);
    auto procAddr = GetProcAddress(cast(void*)moduleHandle, cast(const(char)*)exportedFunction);
    return cast(Address)procAddr;
}

void rvaFillBuffer(Address buffer, ubyte[] data) {
    auto base = cast(Address)GetModuleHandle("rs2client.exe");
    auto loc = cast(Address*)(base + buffer);
    memcpy(cast(void*)loc, data.ptr, data.length);
}

import core.stdc.string;
void rvaMemset(Address address, int newByte, size_t size) {
    auto base = cast(Address)GetModuleHandle("rs2client.exe");
    memset(cast(void*)(base + address), newByte, size);
}
