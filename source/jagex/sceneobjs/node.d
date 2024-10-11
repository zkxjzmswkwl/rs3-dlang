module jagex.sceneobjs.node;

import std.typecons;

import util.types;
import util.misc;
import jagex.constants;
import jagex.sceneobjs.sceneobj;


class Node : SceneObj {
    private Address location;

    this(Address obj) {
        // Can be either 0, 10 or 12.
        auto type = read!ObjectType(obj + 0x10);
        if (type == ObjectType.ZERO) {
            this.location = read!Address(obj + 0xB8);
        } else if (type == ObjectType.LOCATION) {
            this.location = read!Address(obj + 0xB0);
        }

        super(obj, type);
    }

    override public string getName() {
        return read!JagString(this.location + 0x1E0).read();
    }

    public uint getServerIndex() {
        return read!uint(this.location + 0x8);
    }
}