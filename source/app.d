import core.sys.windows.dll;

import std.format;
import std.stdio;
import std.concurrency;
import core.runtime;
import core.sys.windows.windows;
import core.thread;
import core.sys.windows.windef;
import core.sys.windows.winnt;
import core.stdc.stdint : uintptr_t;
import core.memory;

import util.types;
import context;
import jagex.jaghooks;

void setup()
{
    AllocConsole();
    freopen("CONOUT$", "w", stdout.getFP);

    // Without this, hitting a breakpoint will cause your mouse to feel as though it's polling at 1hz.
    HHOOK mouseHook = *cast(HHOOK*)(cast(uintptr_t) GetModuleHandle(NULL) + 0xD7CFE8);
    UnhookWindowsHookEx(mouseHook);
}

void cleanup(HMODULE hModule)
{
    FreeConsole();
    fclose(stdout.getFP);
    FreeLibraryAndExitThread(hModule, 0);
}

uintptr_t run(HMODULE hModule)
{
    setup();

    JagexHooks jagexHooks = new JagexHooks();
    jagexHooks.placeAll();

    for (;;)
    {
        Thread.sleep(dur!"msecs"(50));
        if (GetAsyncKeyState(VK_F1) & 1)
        {
            writeln("Ejecting");
            break;
        }
    }

    cleanup(hModule);
    return 0;
}

extern (Windows) BOOL DllMain(HMODULE module_, uint reason, void*) // @suppress(dscanner.style.phobos_naming_convention)
{
    if (reason == DLL_PROCESS_ATTACH)
    {
        Runtime.initialize();
        auto t1 = new Thread({ run(module_); }).start();
    }
    else if (reason == DLL_PROCESS_DETACH)
    {
        Runtime.terminate();
        FreeLibraryAndExitThread(module_, 0);
    }
    return TRUE;
}
