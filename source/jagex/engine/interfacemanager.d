module jagex.engine.interfacemanager;

import slf4d;
import util;
import rdconstants;
import context;
import jagex.globals;

extern(C++)
class InterfaceManager {
    /* 0x00 */ ulong* vtable;
    /* 0x08 */ byte[0x18] pad;
    /* 0x20 */ ulong* interfaceList;
}

ulong getInterfaceManager() {
    return read!Address(ZGetClient().getPtr() + OF_INTERFACE);
}