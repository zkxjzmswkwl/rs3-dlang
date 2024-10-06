import core.sys.windows.dll;

import std.format;
import std.stdio;
import std.string;
import core.runtime;
import core.sys.windows.windows;
import core.thread;
import core.memory;
import core.sys.windows.windef;
import core.sys.windows.winnt;
import core.stdc.stdint : uintptr_t;

import slf4d;

import util.types;
import util.misc;
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
    Runtime.initialize();
    freopen("C:\\ProgramData\\Jagex\\launcher\\runedoc.log", "w", stdout.getFP);
    freopen("C:\\ProgramData\\Jagex\\launcher\\runedoc.log", "w", stderr.getFP);

    JagexHooks jagexHooks = new JagexHooks();
    jagexHooks.placeAll();

    Client jagClient = new Client();
    Varbit varbit = new Varbit(jagClient.getPtr());
    LocalPlayer localPlayer = jagClient.getLocalPlayer();
    SceneManager sceneManager = jagClient.getSceneManager();
    Inventory inventory = jagClient.getInventory();

    uint maxCol = 1065353216;
    uint minCol = 1045353216;
    uint red = minCol;
    uint green = minCol;
    uint blue = minCol;
    uint stepAmt = 20000000 / 90;

    uint phase = 0;

    for (;;)
    {
        Thread.sleep(dur!"msecs"(50));

        switch (phase)
        {
        case 0:
            red += stepAmt;
            green -= stepAmt;

            if (red >= maxCol)
            {
                red = maxCol;
                phase = 1;
            }

            if (green <= minCol)
            {
                green = minCol;
            }
            break;

        case 1: 
            green += stepAmt;
            blue -= stepAmt;

            if (green >= maxCol)
            {
                green = maxCol;
                phase = 2;
            }

            if (blue <= minCol)
            {
                blue = minCol;
            }
            break;

        case 2:
            blue += stepAmt;
            red -= stepAmt;

            if (blue >= maxCol)
            {
                blue = maxCol;
                phase = 0;
            }

            if (red <= minCol)
            {
                red = minCol;
            }
            break;

        default:
                break;
        }

        if (red == minCol && green == minCol && blue == minCol)
            phase = 0;

        rvaWrite!uint(0xB63B74, red);
        rvaWrite!uint(0xB63B74 + 0x4, green);
        rvaWrite!uint(0xB63B74 + 0x8, blue);

        // Testing etc.
        // TODO: Remove
        if (GetAsyncKeyState(VK_LEFT) & 1)
        {
            auto curHp = varbit.getCurrentHealth();
            auto maxHp = varbit.getMaxHealth();
            auto sp = varbit.getSummoningPoints();
            auto pp = varbit.getPrayerPoints();
            infoF!"HP: %d/%d Summoning points: %d Prayer points: %d"(curHp, maxHp, sp, pp);
        }

        if (GetAsyncKeyState(VK_UP) & 1)
        {
            infoF!"Scripture state: %d"(varbit.getInv(94, 17, 30602));
            infoF!"Scripture ticks: %d"(varbit.getInv(94, 17, 30603));
        }
    }

    GC.collect();
    fclose(stdout.getFP);
    fclose(stderr.getFP);
    return 0;
}

extern (Windows) BOOL DllMain(HMODULE hModule, uint reason, void*) // @suppress(dscanner.style.phobos_naming_convention)
{
    if (reason == DLL_PROCESS_ATTACH)
    {
        CloseHandle(
            CreateThread(
                cast(SECURITY_ATTRIBUTES*) NULL,
                cast(ulong) 0,
                cast(LPTHREAD_START_ROUTINE) &run,
                cast(PVOID) hModule,
                cast(uint) 0,
                cast(uint*) NULL
            )
        );
    }
    else if (reason == DLL_PROCESS_DETACH)
    {
        Runtime.terminate();
    }
    return TRUE;
}
