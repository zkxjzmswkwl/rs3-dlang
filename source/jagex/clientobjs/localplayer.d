module jagex.clientobjs.localplayer;

import slf4d;

import util.misc;
import util.types;
import jagex.clientobjs.clientobj;

class LocalPlayer : ClientObj
{
    this(Address clientPtr)
    {
        super(clientPtr, 0x19F50);
        super.logPtr();

        infoF!"Logged in as %s"(this.getName());
        if (this.isMember()) {
            infoF!"This account (%s) is currently a member."(this.getName());
        } else {
            infoF!"This account (%s) is not currently a member."(this.getName());
        }
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