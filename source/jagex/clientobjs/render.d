module jagex.clientobjs.render;

import slf4d;

import util;
import rdconstants;
import jagex.clientobjs.clientobj;
import jagex.sceneobjs.entity;
import jagex.hooks;
import context;

class Render : ClientObj {
    this(Address clientPtr) {
        super(clientPtr, OF_RENDERER);
        super.logPtr();
        this.obj = read!Address(this.obj + 0x40);
        this.obj = read!Address(this.obj + 0x8);
    }
}