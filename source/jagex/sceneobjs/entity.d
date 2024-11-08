module jagex.sceneobjs.entity;

import std.typecons;
import std.format;

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

    public void forceHighlight() {
        write!int(this.obj + 0x1100, 0);
    }

    public string asString() {
        return format("%s#%d#%d#%d",
            this.getName(),
            this.getCombatLevel(),
            this.getServerIndex(),
            this.obj);
    }

    public Address getSilhouette() {
        return read!Address(this.obj + 0xC68);
    }

    public void setSilhouette(float r, float g, float b, float opacity, float width) {
        auto silhouette = read!Address(this.obj + 0xC68);
        write!float(silhouette + 0x100, r);
        write!float(silhouette + 0x104, g);
        write!float(silhouette + 0x108, b);
        write!float(silhouette + 0x10C, opacity);
        write!float(silhouette + 0x110, width);
    }

    public void setSilhouette2(float r, float g, float b, float opacity, float width) {
        auto silhouette = readPtr!Silhouette(this.obj + 0xC68);
        silhouette.set(r, g, b, opacity, width);
    }
}