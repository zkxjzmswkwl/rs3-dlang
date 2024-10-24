module jagex.clientobjs.render;

import slf4d;

import util;
import jagex.clientobjs.clientobj;
import jagex.sceneobjs.entity;
import jagex.hooks;
import context;

class Render : ClientObj {
    this(Address clientPtr) {
        super(clientPtr, 0x199C0);
        super.logPtr();
        this.obj = read!Address(this.obj + 0x40);
        this.obj = read!Address(this.obj + 0x8);
    }

    public void testDrawShit(immutable(char)* text, int x, int y) {
        auto colour = 0xFF0000;
        fnCall(drawStringInnerTrampoline, this.obj, text, x, y, colour, 255, 2);
    }
}