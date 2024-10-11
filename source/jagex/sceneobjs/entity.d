module jagex.sceneobjs.entity;

import std.typecons;

import util;
import jagex.constants;
import jagex.sceneobjs.sceneobj;


class Entity : SceneObj {
    private ObjectType type;

    this(Address obj) {
        // Can be 1 or 2 
        this.type = read!ObjectType(obj + 0x10);
        super(obj, this.type);
        super.nameOffset = 0x90;
        super.tilePosOffset = 0x9C;
    }

    public uint getCombatLevel() {
        if (this.type == ObjectType.PLAYER)
            return read!uint(this.obj + 0x10AC);

        return read!uint(this.obj + 0x1160);
    }

    public uint getTotalLevel() {
        if (this.type == ObjectType.NPC)
            return 0;
        
        return read!uint(this.obj + 0x10B8);
    }

    public int getAnimation() {
        return read!int(this.obj + 0xA90);
    }

    public int getFollowing() {
        return read!int(this.obj + 0x184);
    }

    public int getServerIndex() {
        return read!uint(this.obj + 0x88);
    }
}