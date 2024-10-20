module plugins.interrupt;

import core.sys.windows.windows;
import std.format;

class Interrupt : Exception {
    this() {
        super("", "", 0);
    }
}