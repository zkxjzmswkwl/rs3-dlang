module jagex.hooks;

import std.stdio;
import std.format;
import std.string;
import std.conv;
import core.sys.windows.windows;

import slf4d;

import context;
import util.misc;
import util.types;
import jagex.client;
import jagex.sceneobjs;
import jagex.engine.functions;
import plugins;


///
/// Must be __gshared or shared.
/// If not, we won't be able to call from the game thread, which means we'd always crash in the hook.
///
__gshared Address chatTrampoline;
__gshared Address updateStatTrampoline;
__gshared Address getInventoryTrampoline;
__gshared Address highlightEntityTrampoline;
__gshared Address swapBuffersTrampoline;
__gshared Address renderMenuEntryTrampoline;
__gshared Address runClientScriptTrampoline;
__gshared Address highlightTrampoline;
__gshared Address addEntryInnerTrampoline;

extern (Windows) void hookAddChat(
    void* a1,
    int messageType,
    int a3,
    void* a4,
    JagString* author,
    void* a6,
    void* a7,
    JagString* message,
    void* a9,
    void* a10,
    int a11
)
{
    pragma(inline, false);
    pragma(optimize, false);

    auto pm = PluginManager.get();
    pm.onChat(messageType, author.read(), message.read());

    fnCall(chatTrampoline, a1, messageType, a3, a4, author, a6, a7, message, a9, a10, a11);
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
extern (C)
void hookSwapBuffers(HDC hDc) {
    // Ensure the window handle is set
    if (Context.get().getWindowHandle() is null) {
        auto window = WindowFromDC(hDc);
        Context.get().setWindowHandle(window);
    }

    fnCall(swapBuffersTrampoline, hDc);
}

extern(Windows)
void hookRenderMenuEntry(Address* thisptr, ulong index, ulong what) {
    infoF!"RenderMenuEntry: %016X, %016X, %016X"(thisptr, index, what);
    fnCall(renderMenuEntryTrampoline, thisptr, index, what);
}

// Ignore
uint[] blacklistedScripts = [8773, 8298, 10902, 10823, 13824, 1269, 10902, 1652, 8415];
extern(Windows)
void hookRunClientScript(Address* thisptr, Address* script, int a3) {
    auto scriptId = *cast(uint*)script;
    foreach (bs; blacklistedScripts) {
        if (scriptId == bs) {
            goto ret;
        }
    }

    infoF!"RunClientScript: %016X, %d, %d"(thisptr, scriptId, a3);
ret:
    fnCall(runClientScriptTrampoline, thisptr, script, a3);
}

extern(Windows)
void hookHighlight(Address entity, ulong unsure) {
    fnCall(highlightTrampoline, entity, unsure);
}

// 14edd0
extern(Windows)
void hookAddEntryInner(Address* thisptr, void* optionStr, void* objNameStr, void* type, void* idk, void* idk2, void* idk3, void* idk4, void* idk5, void* idk6) {
    infoF!"AddEntryInner: %016X %016X %016X %016X %016X %016X %016X %016X %016X %016X"(thisptr, optionStr, objNameStr, type, idk, idk2, idk3, idk4, idk5, idk6);
    fnCall(addEntryInnerTrampoline, thisptr, optionStr, objNameStr, type, idk, idk2, idk3, idk4, idk5, idk6);
}