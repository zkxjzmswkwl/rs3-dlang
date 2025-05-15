module jagex.clientobjs.localplayer;

import slf4d;

import util;
import rdconstants;
import jagex.clientobjs.clientobj;
import jagex.sceneobjs.entity;

class LocalPlayer : ClientObj {
    this(Address clientPtr) {
        super(clientPtr, OF_LOGGED_IN_PLAYER);
        super.logPtr();

        infoF!"Logged in as %s"(this.getName());
        infoF!"Resolved LoggedInPlayer entity at %016X"(this.resolvePathingEntity());
        if (this.isMember()) {
            infoF!"This account (%s) is currently a member."(this.getName());
        } else {
            infoF!"This account (%s) is not currently a member."(this.getName());
        }
    }

    public string getName() {
        return read!JagString(this.obj + 0x68).read();
    }

    public bool isMember() {
        return read!bool(this.obj + 0x28);
    }

    public Entity getEntity() {
        return new Entity(resolvePathingEntity());
    }

    private Address resolvePathingEntity() {
        auto index = read!uint(this.obj + 0x48);
        auto playerList = read!Address(this.clientPtr + OF_PLAYER_LIST);
        return resolvePtrChain(playerList, [0x10, index * 0x8, 0x38]);
    }
}