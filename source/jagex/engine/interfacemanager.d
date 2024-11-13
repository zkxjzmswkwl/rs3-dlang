module jagex.engine.interfacemanager;

import slf4d;
import util;
import context;

extern(C++)
class InterfaceManager {
    /* 0x00 */ ulong* vtable;
    /* 0x08 */ byte[0x18] pad;
    /* 0x20 */ ulong* interfaceList;
}

ulong getInterfaceManager() {
    return read!Address(Context.get().client().getPtr() + 0x198C8);
}