import core.sys.windows.dll;
import jagex.constants;
import jagex.sceneobjs;

import slf4d;

import std.stdio;
import core.runtime;
import core.sys.windows.windows;
import std.conv;

import jagex;
import context;
import tracker;
import util;
import rdconstants;
import comms.server;
import jagex.engine.patches;
import plugins;
import plugins.highlighter;
import plugins.chatexample.chatexample;
import plugins.afkwarden.afkwarden;
import jagex.globals;

TrackerManager gTrackerManager;
Server         gICPServer;

void registerPlugins() {
    auto highlighter = new Highlighter();
    auto logChat     = new ChatExample();
    auto afkWarden   = new AFKWarden();

    auto pm = PluginManager.get();
    pm.addPlugin(highlighter);
    pm.addPlugin(logChat);
    pm.addPlugin(afkWarden);
    info("Registered plugins.");
}

void prelude() {
    // stdout/stderr -> file
    freopen("C:\\ProgramData\\Jagex\\launcher\\runedoc.log", "w", stdout.getFP);
    freopen("C:\\ProgramData\\Jagex\\launcher\\runedoc.log", "w", stderr.getFP);
    // Useful
    infoF!"Client ptr: %016X"(ZGetClient().getPtr());
    // Horrible, this shouldn't even be the module's job to begin with.
    gTrackerManager = Context.get().tManager;
    // Apply whatever byte patches I currently (and likely falsely) assume to not cause crashes.
    applyPatches();
    // This, again, should not be the job of the module. Goal post for v1.0.0?
    registerPlugins();
    // Create instance of `Server : Thread`, start thread, return instance.
    gICPServer = Server.bootstrap();
}

uint run() {
    try {
        prelude();

        for (;;) {
            gTrackerManager.checkActivity();
            Thread.sleep(dur!"msecs"(300));

			if (GetAsyncKeyState(VK_F1) & 1) {
                ZGetHooks().disableAll();
				break;
			}
        }

        // Any cleanup here.
        fclose(stdout.getFP);
        fclose(stderr.getFP);
    } catch (Exception ex) {
        writeln(ex.msg ~ " " ~ ex.file ~ " " ~ ex.line.to!string);
    }

    // Clean up running threads
	gTrackerManager.stopAll();
	gICPServer.killSelf();

    // Free both Capstone and ourselves.
    auto capstoneHandle = GetModuleHandleA("capstone.dll");
	auto selfHandle = GetModuleHandleA("DeOppressoLiber.dll");
	FreeLibrary(capstoneHandle);
    // This results DLL_PROCESS_DETACH being called, which is great.
	FreeLibrary(selfHandle);
	return 0;
}

extern(Windows)
BOOL DllMain(HINSTANCE hInstance, DWORD ulReason, LPVOID reserved)
{
    import core.sys.windows.winnt;
    import core.sys.windows.dll :
        dll_process_attach, dll_process_detach,
        dll_thread_attach, dll_thread_detach;
    switch (ulReason)
    {
        default: assert(0);
        case DLL_PROCESS_ATTACH:
            dll_process_attach( hInstance, true );
            new Thread({ run(); }).start();
            return true;

        case DLL_PROCESS_DETACH:
            dll_process_detach( hInstance, true );
            return true;

        case DLL_THREAD_ATTACH:
            return dll_thread_attach( true, true, hInstance );

        case DLL_THREAD_DETACH:
            return dll_thread_detach( true, true, hInstance );
    }
}
