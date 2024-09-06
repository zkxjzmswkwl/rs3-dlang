module kronos.hook;

import core.sys.windows.windows;
import std.algorithm.comparison;
import core.stdc.string;
import util.types;

class Hook {
    // For debugging/logging.
    private string name;

    ///
    /// Where we're placing the jmp.
    ///
    private Address location;
    /// 
    /// Location of our mapped function.
    ///
    private Address jmpTo;

    this(Address location, string name) {
        this.location = location;
        this.name = name;
    }

    // TODO: tramp back to original function bytes
    // currently this shit useless 
    public void place(void* ourFunction) {
        void* relayPage = this.writeRelayPage();
        this.writeJmp(relayPage, ourFunction);

        DWORD previousProtection;
        // take da condom off
        VirtualProtect(cast(void*)location, 1024, PAGE_EXECUTE_READWRITE, &previousProtection);

        ubyte[] jmpIsns32 = [0xE9, 0x0, 0x0, 0x0, 0x0];
        // this math is fucked but im too drunk to fix it 
        ulong relativeAddress = (cast(ulong)relayPage - ((cast(ulong)location + jmpIsns32.sizeof))) + 11;
        memcpy(&jmpIsns32[1], &relativeAddress, 4);
        memcpy(cast(void*)location, jmpIsns32.ptr, jmpIsns32.sizeof);

        // put da condom back on
        VirtualProtect(cast(void*)location, 1024, previousProtection, null);
    }

    private void writeJmp(void* jmpMem, void* jmpLoc) {
        ubyte[] jmpIsns = [
            0x49, 0xBA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x41, 0xFF, 0xE2
        ];

        ulong ulJmpLoc = cast(ulong)jmpLoc;
        memcpy(&jmpIsns[2], &ulJmpLoc, ulJmpLoc.sizeof);
        memcpy(jmpMem, jmpIsns.ptr, jmpIsns.sizeof);
    }

    private void* writeRelayPage() {
        SYSTEM_INFO si;
        GetSystemInfo(&si);
        ulong PAGE_SIZE = si.dwPageSize;

        ulong start = (cast(ulong)location) & ~(PAGE_SIZE - 1);
        ulong minimum = min(start - 0x7FFFFF00, cast(ulong)si.lpMinimumApplicationAddress);
        ulong maximum = min(start + 0x7FFFFF00, cast(ulong)si.lpMaximumApplicationAddress);

        ulong sp = (start - (start % PAGE_SIZE));
        ulong poffset = 1;

        for (;;) {
            ulong boffset = poffset * PAGE_SIZE;
            ulong high = sp + boffset;
            ulong low = (sp > boffset) ? sp - boffset : 0;

            bool exit = high > maximum && low < minimum;
            if (high < maximum) {
                void* outLoc = VirtualAlloc(
                    cast(void*)high,
                    PAGE_SIZE, 
                    MEM_COMMIT | MEM_RESERVE,
                    PAGE_EXECUTE_READWRITE
                );

                if (outLoc != null) {
                    return outLoc;
                }
            }

            if (low > minimum) {
                void* outLoc = VirtualAlloc(
                    cast(void*)low,
                    PAGE_SIZE,
                    MEM_COMMIT | MEM_RESERVE,
                    PAGE_EXECUTE_READWRITE
                );

                if (outLoc != null) {
                    return outLoc;
                }
            }

            poffset++;

            if (exit)
                break;
        }
        return null;
    }
}