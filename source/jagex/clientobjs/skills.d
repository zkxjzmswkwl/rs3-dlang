module jagex.clientobjs.skills;

import util;
import rdconstants;
import jagex.clientobjs.clientobj;

class Skills: ClientObj {
    this(Address clientPtr) {
        super(clientPtr, OF_SKILL_MANAGER);
        super.logPtr();
    }
}