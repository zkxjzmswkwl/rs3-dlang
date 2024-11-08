module util.types;

import std.conv : to;
import std.format;
import std.string;
import core.stdc.string;
import core.stdc.stdlib : malloc;

alias Address = ulong;
alias HookedArgPtr = ulong*;

template offset(uint off)
{
    mixin("char[" ~ to!string(off) ~ "] padding_" ~ to!string(off) ~ ";");
}

struct JagVector(V)
{
    V* _begin;
    V* _end;
    void* capacity;

    // Index operator (const and non-const)
    @property V opIndex(size_t index) const
    {
        return _begin[index];
    }

    @property V opIndex(size_t index)
    {
        return _begin[index];
    }

    // `at` function to access elements
    V at(size_t index)
    {
        return _begin[index];
    }

    // Size function
    @property size_t size() const
    {
        return cast(size_t)(_end - _begin);
    }

    // Begin and end iterators (non-const and const versions)
    V* begin()
    {
        return _begin;
    }

    V* end()
    {
        return _end;
    }

    const(V)* cbegin() const
    {
        return _begin;
    }

    const(V)* cend() const
    {
        return _end;
    }

    // Check if the vector is empty
    @property bool empty() const
    {
        return _begin == _end;
    }
}

struct JagArray(T)
{
    ulong _1;
    size_t size;
    T* data;

    T opIndex(size_t index) const
    {
        return data[index];
    }

    T opIndex(size_t index)
    {
        return data[index];
    }

    // Iterators
    T* begin()
    {
        return data;
    }

    T* end()
    {
        return data + size;
    }

    const(T)* cbegin() const
    {
        return data;
    }

    const(T)* cend() const
    {
        return data + size;
    }

    bool empty() const
    {
        // || size == 0 ?
        return data is null;
    }
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

    JagString opAssign(string val)
    {
        this.set(toStringz(val));
        return this;
    }

    public void set(immutable(char)* val)
    {
        if (isHeap())
        {
            heap.data = cast(char*) val;
        }
        else
        {
            auto sz = fromStringz(val).length;
            memcpy(raw.data.ptr, val, sz);
        }
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
        return !isHeap;
    }

    string read() const
    {
        if (isHeap)
        {
            return to!string(heap.data);
        }
        return to!string(raw.data.ptr);
    }

    char* readCstr()
    {
        if (isHeap)
        {
            return heap.data;
        }
        return raw.data.ptr;
    }

    string fromCstr()
    {
        return cast(string)fromStringz(readCstr());
    }

    @property size_t size() const
    {
        return read().length;
    }
}

struct ForeignObjFixed(int size)
{
    char[size] data;
}

enum ClientState : int
{
    LOGIN = 10,
    LOBBY = 20,
    IN_GAME = 30,
}

struct SharedPtr(T) {
    this(T* ptr) {
        this.ptr = ptr;
    }

    void* blah;
    T* ptr;
}

struct Interaction {
    this(uint identifier, int x, int y) {
        this.identifier = identifier;
        this.x = x;
        this.y = y;
    }

    ubyte[0x48] pad;
    uint identifier;
    int x;
    int y;
}


struct Silhouette {
    char[0x100] pad;
    // 0x100
    float r;
    // 0x104
    float g;
    // 0x108
    float b;
    // 0x10C
    float opacity;
    // 0x110
    float width;

    void set(float r, float g, float b, float opacity, float width) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.opacity = opacity;
        this.width = width;
    }
}