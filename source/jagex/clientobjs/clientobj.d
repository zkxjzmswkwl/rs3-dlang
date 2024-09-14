module jagex.clientobjs.clientobj;

import slf4d;

import util.types;
import util.misc;

class ClientObj
{
    ///
    /// Offset from jag::Client at which a pointer to a given obj is located.
    ///
    protected Address offset;
    protected Address obj;

    this(Address clientPtr, Address offset)
    {
        this.offset = offset;
        this.obj = read!Address(clientPtr + offset);
    }

    protected void logPtr()
    {
        infoF!"%s: %016X"(this.classinfo.name, this.obj);
    }
}