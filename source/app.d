import core.sys.windows.dll;

import std.format;
import std.stdio;
import std.string;
import std.concurrency;
import core.runtime;
import core.sys.windows.windows;
import core.thread;
import core.sys.windows.windef;
import core.sys.windows.winnt;
import core.stdc.stdint : uintptr_t;
import core.memory;

import slf4d;

import util.types;
import context;
import jagex.item;
import jagex.jaghooks;
import jagex.client;
import jagex.constants;
import jagex.clientobjs.localplayer;
import jagex.clientobjs.inventory;
import tracker.tracker;
import comms.pipes;
import tracker.trackermanager;


uintptr_t run(HMODULE hModule)
{

    // Maybe `stdoutLog` needs to be an lvalue so it can be kept alive?
    // Edit: No fucking clue why this doesn't work. No exceptions thrown, no crash.
    // Just no logging to that file. At a loss. Moving on.
    // auto stdoutLog = toStringz(Context.get().getWorkingDir() ~ "output.log");
    // freopen(stdoutLog, "w", stdout.getFP);

    freopen("C:/Users/owcar/personal/rsd/output.log", "w", stdout.getFP);
    freopen("C:/Users/owcar/personal/rsd/output.log", "w", stderr.getFP);

    JagexHooks jagexHooks = new JagexHooks();
    jagexHooks.placeAll();

    if (Context.get().isDebugMode())
    {
        info("Debug mode enabled.");
    }

    Client jagClient = new Client();
    LocalPlayer localPlayer = jagClient.getLocalPlayer();
    Inventory inventory = jagClient.getInventory();

    infoF!"Logged in as %s"(localPlayer.getName());
    if (localPlayer.isMember()) {
        infoF!"This account (%s) is currently a member."(localPlayer.getName());
    } else {
        infoF!"This account (%s) is not currently a member."(localPlayer.getName());
    }

    for (;;)
    {
        Thread.sleep(dur!"msecs"(50));

        if (Exfil.get().skillArrayBaseLoc != 0x0 && !(Context.get().tManager is null))
        {
            Context.get().instantiateTrackerManager();
        }

        // Testing etc.
        // TODO: Remove
        if (GetAsyncKeyState(VK_RIGHT) & 1)
        {
            NamedPipe commsTest = new NamedPipe("BigOlDongs");
            commsTest.start();
        }
    }

    fclose(stdout.getFP);
    fclose(stderr.getFP);
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