module jagex.hooks;

import std.stdio;
import std.format;
import std.string : toStringz;
import std.conv;
import core.sys.windows.windows;

import slf4d;

import context;
import util.misc;
import util.types;
import jagex.client;
import jagex.sceneobjs;
import plugins;
import jagex.engine.functions;

///
/// Must be __gshared or shared.
/// If not, we won't be able to call from the game thread, which means we'd always crash in the hook.
///
__gshared Address npcGeneralTrampoline;
__gshared Address npcTrampoline;
__gshared Address nodeTrampoline1;
__gshared Address chatTrampoline;
__gshared Address updateStatTrampoline;
__gshared Address getInventoryTrampoline;
__gshared Address highlightEntityTrampoline;
__gshared Address swapBuffersTrampoline;
__gshared Address drawStringInnerTrampoline;
/// Unused.
__gshared Address setForegroundTrampoline;

mixin template GenDoActionHookBody(string funcName, alias trampolineFunc) {
    enum code = q{
        extern(Windows) void %s(HookedArgPtr sp, SharedPtr!Interaction* miniMenu) {
            fnCall(%s, sp, miniMenu);
        }
    }.format(funcName, trampolineFunc.stringof);
    mixin(code);
}

extern(Windows)
void hookNode1(HookedArgPtr sp, SharedPtr!Interaction* miniMenu) {
    Interaction* action = miniMenu.ptr;
    writefln("%d, %d, %d",action.identifier, action.x, action.y);

    fnCall( nodeTrampoline1, sp, miniMenu );
}

extern(Windows)
void hookNpcGeneral(HookedArgPtr clientPtr, void* clientProt, SharedPtr!Interaction* miniMenu) {
    Interaction* action = miniMenu.ptr;
    writefln("%d, %d, %d",action.identifier, action.x, action.y);

    fnCall( npcGeneralTrampoline, clientPtr, clientProt, miniMenu );
}

extern (Windows)
void hookNpc1(HookedArgPtr sp, HookedArgPtr clientProt) {
    writefln("Client shared ptr: %016X", sp);
    writefln("Client Prot: %016X", clientProt);

    fnCall(npcTrampoline, sp, clientProt);
}

extern (Windows) void hookAddChat(
    void* a1,
    int a2,
    int a3,
    void* a4,
    JagString* a5,
    void* a6,
    void* a7,
    JagString* a8,
    void* a9,
    void* a10,
    int a11
)
{
    pragma(inline, false);
    pragma(optimize, false);
    // Log shit
    infoF!"(%d) %s: %s"(a2, a5.read(), a8.read());

    // Just filter the annoying "Ability not ready yet." message, for now.
    // if (a8.toString() != "Ability not ready yet.") {
    //     fnCall(chatTrampoline, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11);
    // }
    fnCall(chatTrampoline, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11);
}

extern(Windows)
void hookUpdateStat(uint** skillPtr, uint newSkillTotalExp) {
    auto skillId = **skillPtr;
    auto curArrayOffset = skillId * 0x18;
    auto arrayBase = cast(ulong)(skillPtr) - curArrayOffset;

    if (Exfil.get().skillArrayBaseLoc == 0x0) {
        Exfil.get().setSkillArrayBase(arrayBase);
    }

    // We exfiltrate the memory location pointing to an array of skills/their xp from this hook.
    // We wait until that data has been exfiltrated before we can track anything.
    // Overuse of Singletons is an unfortunate side effect of the game thread calling the shots.
    if (!Context.get().tManager.isTrackerActive!uint(skillId)) {
        writefln("Starting tracker thread for skill: %d", skillId);
        Context.get().tManager.startTracker(skillId);
    }

    fnCall(updateStatTrampoline, skillPtr, newSkillTotalExp);
}

extern(Windows)
void hookGetInventory(ulong* rcx, int inventoryId, void* a3) {
    writefln("Inventory ID: %d", inventoryId);
    fnCall(getInventoryTrampoline, rcx, inventoryId, a3);
}

extern(Windows)
BOOL hookSetForegroundWindow(HWND hWnd) {
    return 1;
}

extern(Windows)
void hookHighlightEntity(Address entityPtr, uint highlightVal, char a3, float colour) {
    auto pm = PluginManager.get();
    try {
        pm.onHighlightEntity(new Entity(entityPtr), highlightVal, a3, colour);
    } catch (Interrupt i) {
        return;
    }
    fnCall(highlightEntityTrampoline, entityPtr, highlightVal, a3, colour);
}

// Called at the end of each frame.
// SwapBuffers is responsible for turning the frame.
// `extern(C)` is used to tell the compiler that this function should 
// have the calling convention __stdcall.
extern(C)
void hookSwapBuffers(HDC hDc) {
    if (Context.get().getWindowHandle() is null) {
        Context.get().setWindowHandle(WindowFromDC(hDc));
    }

    // Maybe here better. Rendering thread.
    // If we crash, JagString is fuuuuuucked.
    // testDrawShit(cast(immutable(char)*)&Context.get().largeStr, 1600, 800);

    fnCall(swapBuffersTrampoline, hDc);
}

extern(Windows)
// void hookDrawStringInner(JagString *text, size_t *len, long a3, uint a4, char a5, bool shouldRender) {
void hookDrawStringInner(ulong* thisptr, char *text, int x, int y, int colour, int opacity, char type) {
    if (text) {
        writefln(
            "DrawStringInner: %s\n%d, %d, %d, %d",
            text.to!string,
            x, y, colour, opacity
        );
        writeln("==================================================");
    }
    // immutable(char)* aaa = "HELLFIRE RAGECOCKS".toStringz();
    fnCall(drawStringInnerTrampoline, thisptr, text, x, y, colour, opacity, type);
}
