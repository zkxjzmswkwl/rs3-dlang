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

import colorize;
///
/// Logging
///
import slf4d;

import util.types;
import context;
import jagex.item;
import jagex.jaghooks;
import jagex.client;
import jagex.constants;
import jagex.clientobjs.localplayer;
import jagex.clientobjs.inventory;

void setup()
{
    // TODO: Make this configurable.
    freopen("C:/Users/owcar/personal/rsd/output.log", "w", stdout.getFP);
}

void cleanup(HMODULE hModule)
{
    fclose(stdout.getFP);
}

uintptr_t run(HMODULE hModule)
{
    setup();

    JagexHooks jagexHooks = new JagexHooks();
    jagexHooks.placeAll();

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
        if (GetAsyncKeyState(VK_F1) & 1)
        {
            info("Ejecting");
            break;
        }

        // Testing etc.
        // TODO: Remove
        if (GetAsyncKeyState(VK_RIGHT) & 1)
        {
            auto itemStacks = inventory.getItems();
            ItemStack first = itemStacks[0];
            first.getItem().resolve();

            foreach (stack; itemStacks)
            {
                infoF!"Item: %s, Amount: %d"(stack.getItem().getId(), stack.getAmount());
            }
        }

        if (GetAsyncKeyState(VK_LEFT) & 1)
        {
            SkillExpTable woodcutting = Exfil.get().getSkillExpTable(Skill.WOODCUTTING);
            infoF!"Woodcutting XP: %d, Current Level: %d, Boosted Level: %d"(woodcutting.xp, woodcutting.currentLevel, woodcutting.boostedLevel);
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
