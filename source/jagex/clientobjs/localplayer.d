module jagex.clientobjs.localplayer;

import util.misc;
import util.types;
import jagex.clientobjs.clientobj;

class LocalPlayer : ClientObj
{
    this(Address clientPtr)
    {
        super(clientPtr, 0x19F50);
        super.logPtr();
    }

    public string getName()
    {
        return read!JagString(this.obj + 0x68).read();
    }

    public bool isMember()
    {
        return read!bool(this.obj + 0x28);
    }
}