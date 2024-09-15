module jagex.hooks;

import std.stdio;
import std.string : toStringz;
import core.sys.windows.windows;

import slf4d;
import colorize;

import util.misc;
import util.types;
import jagex.client;

///
/// Must be __gshared or shared.
/// If not, we won't be able to call from the game thread, which means we'd always crash in the hook.
///
__gshared Address npcTrampoline;
__gshared Address chatTrampoline;
__gshared Address updateStatTrampoline;

extern (Windows)
void hookNpc1(HookedArgPtr sp, HookedArgPtr clientProt)
{
    infoF!"Client shared ptr: %016X"(sp);
    infoF!"Client Prot: %016X"(clientProt);

    fnCall(npcTrampoline, sp, clientProt);
}

extern (Windows)
void hookAddChat(
    void* thisptr,
    int messageGroup,
    int a3,
    JagString* author,
    void* a5,
    void* a6,
    JagString* message,
    void* a8,
    void* a9,
    int a10
)
{
    // Log shit
    if (!message.empty())
        infoF!"%s: %s"(author.read(), message.read());

    // Just filter the annoying "Ability not ready yet." message, for now.
    if (message.read() != "Ability not ready yet.")
        fnCall(chatTrampoline, thisptr, messageGroup, a3, author, a5, a6, message, a8, a9, a10);
}

extern(Windows)
void hookUpdateStat(uint** skillPtr, uint newSkillTotalExp)
{
    infoF!"skillPtr (%016X) : newSkillTotalExp (%d)"(skillPtr, newSkillTotalExp);

    auto skillId = **skillPtr;
    auto curArrayOffset = skillId * 0x18;
    auto arrayBase = cast(ulong)(skillPtr) - curArrayOffset;

    if (Exfil.get().getSkillArrayBase() == 0x0)
    {
        Exfil.get().setSkillArrayBase(arrayBase);
    }

    infoF!"arrayBase (%016X)"(arrayBase);
    infoF!"Received exp for skill id (%d)"(**skillPtr);

    fnCall(updateStatTrampoline, skillPtr, newSkillTotalExp);
}