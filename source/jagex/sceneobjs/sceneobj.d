module jagex.sceneobjs.sceneobj;

import std.typecons;

import slf4d;

import util;
import jagex.constants;

abstract class SceneObj
{
    protected Address obj;
    protected Address graphNode;
    protected ObjectType type;

    protected Address nameOffset;
    // This can be in one of two forms:
    //      struct {
    //          float x;
    //          float y;
    //      }
    // Which will be contained in the GraphNode (this]0x8) of the SceneObject, located at [0xEC, 0xF4].
    // -- or --
    //      struct {
    //          uint32_t x;
    //          uint32_t y;
    //      }
    // -
    // If given the former, you must resolve the coordinates with:
    //     uint x = read!uint(this.obj + this.tilePosOffset) / 512;
    //     uint y = read!uint(this.obj + this.tilePosOffset) / 512;
    // - 
    // If given the ladder, there's no extra work to be done and those are the tile coordinates.
    // At times, for a reason unknown to me, both will be populated and [0x16C, 0x170] will each be off by one.
    protected Address tilePosOffset;

    this(Address obj, ObjectType type)
    {
        this.obj = obj;
        this.type = type;

        this.graphNode = read!Address(this.obj + 0x8);
    }

    public string getName()
    {
        return read!JagString(this.obj + this.nameOffset).read();
    }

    public Tuple!(uint, uint) getTilePos()
    {
        auto xf = read!float(this.graphNode + 0xEC);
        auto yf = read!float(this.graphNode + 0xF4);
        return tuple(cast(uint)(xf / 512.0f), cast(uint)(yf / 512.0f));
    }

    protected void logPtr()
    {
        infoF!"SceneObj ptr: %016X"(this.obj);
    }
}