import core.sys.windows.dll;

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
import kronos.hook;
import context;
import capstone;

Address MODULE_BASE = 0;
Address npcAction = 0x117550;

///
/// Must be __gshared or shared.
/// If not, we won't be able to call from the game thread, which means we'd always crash in the hook.
///
__gshared Address npcTrampoline;

template fn(T...)
{
    alias FnProto = extern (Windows) void function(T);

    void call(Address loc, T args)
    {
        FnProto func = cast(FnProto) loc;
        func(args);
    }
}

void hookNpc1(HookedArgPtr sp, HookedArgPtr clientProt)
{
    writeln("Shared client ptr: ", sp);
    writeln("Client Prot: ", clientProt);

    fn!(HookedArgPtr, HookedArgPtr).call(npcTrampoline, clientProt, sp);
}

void setup()
{
    AllocConsole();
    freopen("CONOUT$", "w", stdout.getFP);

    MODULE_BASE = cast(Address) GetModuleHandle(null);

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

    Capstone cs = create(Arch.x86, ModeFlags(Mode.bit64));
    Hook hook = new Hook(MODULE_BASE + npcAction, &cs, "npc1");
    hook.place(&hookNpc1, cast(void**)&npcTrampoline);

    writeln("npcTrampoline: ", npcTrampoline);

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
