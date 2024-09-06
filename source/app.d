import core.sys.windows.dll;

import std.stdio;
import core.runtime;
import core.sys.windows.windows;
import std.concurrency;
import core.thread;
import core.stdc.stdint : uintptr_t;
import core.sys.windows.windef;
import core.sys.windows.winnt;
import std.format;
import util.types;
import kronos.hook;
import context;

Address DO_ACTION_NPC_1 = 0x117550;
alias _function = extern(C) void function(void*, void*);

void hookNpc1(void* sp, void* clientProt) {
	writeln(sp);
	writeln(clientProt);
}

uintptr_t Run(HMODULE hModule) {
	if (!Runtime.initialize()) {
		MessageBox(null, "Failed to initialize runtime.", "Error", MB_OK);
		return 0;
	}
	AllocConsole();
	freopen("CONOUT$", "w", stdout.getFP);

	Address MODULE_BASE = cast(Address)GetModuleHandle(null);
	Hook hook = new Hook(MODULE_BASE + DO_ACTION_NPC_1, "npc1");
	hook.place(&hookNpc1);

	for (;;) {
		Thread.sleep(dur!"msecs"(50));
		if (GetAsyncKeyState(VK_F1) & 1) {
			writeln("Ejecting");
			break;
		}
	}

	FreeConsole();
	fclose(stdout.getFP);

	if (!Runtime.terminate()) {
		MessageBox(null, "Failed to terminate runtime.", "Error", MB_OK);
	}
	FreeLibraryAndExitThread(hModule, 0);
	return 0;
}

extern (Windows) BOOL DllMain(HMODULE module_, uint reason, void*) {
	if (reason == DLL_PROCESS_ATTACH) {
		Runtime.initialize();
		auto t1 = new Thread({Run(module_); }).start();
	} else if (reason == DLL_PROCESS_DETACH) {
		Runtime.terminate();
		FreeLibraryAndExitThread(module_, 0);
	}
	return TRUE;
}
