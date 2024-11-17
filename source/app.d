import core.sys.windows.dll;

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
import jagex.clientobjs.chathistory : ChatMessage;
import plugins;
import plugins.highlighter;
import plugins.chatexample.chatexample;
import plugins.afkwarden.afkwarden;
import jagex.engine.functions;

void registerPlugins() {
    auto highlighter = new Highlighter();
    auto logChat     = new ChatExample();
    auto afkWarden   = new AFKWarden();

    auto pm = PluginManager.get();
    pm.addPlugin(highlighter);
    pm.addPlugin(logChat);
    pm.addPlugin(afkWarden);
}

void run(HMODULE hModule) {
    try {
        freopen("C:\\ProgramData\\Jagex\\launcher\\runedoc.log", "w", stdout.getFP);
        freopen("C:\\ProgramData\\Jagex\\launcher\\runedoc.log", "w", stderr.getFP);
        infoF!"Client ptr: %016X"(Context.get().client().getPtr());

        TrackerManager trackerManager = Context.get().tManager;
        JagexHooks jagexHooks = new JagexHooks();
        jagexHooks.enableAll();
        applyPatches();
        registerPlugins();

        Server server = new Server(SERVER_IP, SERVER_PORT);
        server.start();

        for (;;) {
            trackerManager.checkActivity();
            Thread.sleep(dur!"msecs"(300));
        }

        fclose(stdout.getFP);
        fclose(stderr.getFP);
    } catch (Exception ex) {
        writeln(ex.msg ~ " " ~ ex.file ~ " " ~ ex.line.to!string);
    }
}

extern (Windows) BOOL DllMain(HMODULE module_, uint reason, void*) { // @suppress(dscanner.style.phobos_naming_convention) {
    if (reason == DLL_PROCESS_ATTACH) {
        Runtime.initialize();
        auto t1 = new Thread({ run(module_); }).start();
    }
    else if (reason == DLL_PROCESS_DETACH) {
        Runtime.terminate();
        FreeLibrary(module_);
    }
    return TRUE;
}
