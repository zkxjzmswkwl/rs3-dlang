module jagex.clientobjs.skills;

import util.misc;
import util.types;
import jagex.clientobjs.clientobj;

class Skills: ClientObj
{
    this(Address clientPtr)
    {
        super(clientPtr, 0x198E8);
        super.logPtr();
    }
}