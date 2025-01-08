module jagex.clientobjs.clientobj;

import slf4d;

import util;

class ClientObj {
    ///
    /// Offset from jag::Client at which a pointer to a given obj is located.
    ///
    protected Address offset;
    protected Address obj;
    protected Address clientPtr;

    this(Address clientPtr, Address offset) {
        this.clientPtr = clientPtr;
        this.offset = offset;
        this.obj = read!Address(clientPtr + offset);
    }

    protected void logPtr() {
        infoF!"%s: %016X"(this.classinfo.name, this.obj);
    }
}
