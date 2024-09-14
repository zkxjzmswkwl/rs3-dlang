module util.types;

import std.conv;
import std.format;
import std.string;
import core.stdc.string;

alias Address = ulong;
alias HookedArgPtr = ulong*;

template offset(uint offset)
{
    mixin("char[" ~ to!string(offset) ~ "] padding_" ~ to!string(offset) ~ ";");
}

struct JagString
{
    struct HeapLayout
    {
        char* data;
        size_t size;
        size_t capacity;
    }

    struct SSOLayout
    {
        char[HeapLayout.sizeof - char.sizeof] data;
        char size;
    }

    struct RawLayout
    {
        char[HeapLayout.sizeof] data;
    }

    union
    {
        HeapLayout heap;
        SSOLayout sso;
        RawLayout raw;
    }

    @property bool empty() const
    {
        if (isHeap())
        {
            return heap.data is null;
        }
        return raw.data[0] == '\0';
    }

    @property bool isHeap() const
    {
        return (sso.size & 0x80) != 0;
    }

    @property bool isSSO() const
    {
        return !isHeap();
    }

    @property string read() const
    {
        if (isHeap())
        {
            return to!string(heap.data);
        }
        return to!string(raw.data.ptr);
    }

    @property size_t size() const
    {
        return read().length;
    }

    @disable string opAssign(const string);

    @disable this(string);

    @disable string opAssign(string);
}