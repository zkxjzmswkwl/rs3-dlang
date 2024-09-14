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

import util.types;
import kronos.hook;
import context;
import capstone;

Address MODULE_BASE = 0;

/// We'll move these later. cba atm.
Address npcAction = 0x117550;
Address addChat   = 0xCD640;

///
/// Must be __gshared or shared.
/// If not, we won't be able to call from the game thread, which means we'd always crash in the hook.
///
__gshared Address npcTrampoline;
__gshared Address chatTrampoline;

struct Fn(T...)
{
    T args_;
    Address loc_;

    this(Address loc, T args)
    {
        args_ = args;
        loc_ = loc;
    }

    extern (Windows) void call()
    {
        alias FnProto = extern (Windows) void function(T);
        FnProto func = cast(FnProto) loc_;
        func(args_);
    }
}

Fn!(Args) fnCall(Args...)(Address loc, Args args)
{
    auto fn = typeof(return)(loc, args);
    fn.call();
    return fn;
}

extern(Windows) void hookNpc1(HookedArgPtr sp, HookedArgPtr clientProt)
{
    writeln("Shared client ptr: ", sp);
    writeln("Client Prot: ", clientProt);

    fnCall(npcTrampoline, sp, clientProt);
}

extern(Windows) void hookAddChat(
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
    if (message.read() != "Ability not ready yet.")
        fnCall(chatTrampoline, thisptr, messageGroup, a3, author, a5, a6, message, a8, a9, a10);
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

    Hook npcActionHook = new Hook(MODULE_BASE + npcAction, &cs, "npc1");
    npcActionHook.place(&hookNpc1, cast(void**)&npcTrampoline);

    Hook addChatHook = new Hook(MODULE_BASE + addChat, &cs, "addChat");
    addChatHook.place(&hookAddChat, cast(void**)&chatTrampoline);

    writeln("npcTrampoline: ", npcTrampoline);
    writeln("chatTrampoline: ", chatTrampoline);

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
