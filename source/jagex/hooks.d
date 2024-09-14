module jagex.hooks;

import std.stdio;
import std.string : toStringz;
import core.sys.windows.windows;

import util.misc;
import util.types;

///
/// Must be __gshared or shared.
/// If not, we won't be able to call from the game thread, which means we'd always crash in the hook.
///
__gshared Address npcTrampoline;
__gshared Address chatTrampoline;

extern (Windows)
void hookNpc1(HookedArgPtr sp, HookedArgPtr clientProt)
{
    writeln("Shared client ptr: ", sp);
    writeln("Client Prot: ", clientProt);

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
    if (message.read() == "123")
    {
        // testing smth
        *message = "<img=7><col=00ff00>123</col>";
    }

    // Just filter the annoying "Ability not ready yet." message, for now.
    if (message.read() != "Ability not ready yet.")
        fnCall(chatTrampoline, thisptr, messageGroup, a3, author, a5, a6, message, a8, a9, a10);
}
