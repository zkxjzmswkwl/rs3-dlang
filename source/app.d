import core.sys.windows.dll;

import std.format;
import std.stdio;
import std.string;
import core.runtime;
import core.sys.windows.windows;
import core.thread;
import core.sys.windows.windef;
import core.sys.windows.winnt;
import core.stdc.stdint : uintptr_t;

import slf4d;

import util.types;
import context;
import jagex.jaghooks;
import jagex.client;
import jagex.clientobjs.localplayer;
import jagex.clientobjs.scenemanager;
import jagex.clientobjs.inventory;
import jagex.engine.varbit;
import comms.pipes;


ulong run(HMODULE hModule)
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

    Client jagClient = new Client();
    Varbit varbit = new Varbit(jagClient.getPtr());
    LocalPlayer localPlayer = jagClient.getLocalPlayer();
    SceneManager sceneManager = jagClient.getSceneManager();
    Inventory inventory = jagClient.getInventory();

    for (;;)
    {
        Thread.sleep(dur!"msecs"(50));

        // Testing etc.
        // TODO: Remove
        if (GetAsyncKeyState(VK_UP) & 1)
        {
            // sceneManager.recurseGraphNode(0x0);
            // infoF!"Praying melee: %d"(varbit.isPrayingMelee());
            infoF!"Residual Soul count: %d"(varbit.getResidualSoulCount());
        }

        if (GetAsyncKeyState(VK_LEFT) & 1)
        {
            auto curHp = varbit.getCurrentHealth();
            auto maxHp = varbit.getMaxHealth();
            auto sp = varbit.getSummoningPoints();
            auto pp = varbit.getPrayerPoints();
            infoF!"HP: %d/%d Summoning points: %d Prayer points: %d"(curHp, maxHp, sp, pp);
        }

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