module jagex.hooks;

import std.stdio;
import std.format;
import std.string : toStringz;
import core.sys.windows.windows;

import slf4d;

import context;
import util.misc;
import util.types;
import jagex.client;

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
    char* a5,
    char* a6,
    char* a7,
    char* a8,
    char* a9,
    char* a10,
    int a11
) 
{

    auto senderString = cast(JagString*)a5;
    auto msgString = cast(JagString*)a8;
    // // Log shit
    if (!msgString.empty())
        writefln("%s: %s", senderString.read(), msgString.read());

    // Just filter the annoying "Ability not ready yet." message, for now.
    if (msgString.read() != "Ability not ready yet.")
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