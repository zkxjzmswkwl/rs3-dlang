import core.sys.windows.dll;
import jagex.constants;
import jagex.sceneobjs;

import slf4d;

import std.stdio;
import core.runtime;
import core.sys.windows.windows;
import std.conv;

import rd.eventbus;
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
import jagex.globals;

TrackerManager gTrackerManager;
JagexHooks     gJagexHooks;
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
    // Create instance of `JagexHooks`, call `enableAll`, return instance.
    gJagexHooks = JagexHooks.bootstrap();
    // Apply whatever byte patches I currently (and likely falsely) assume to not cause crashes.
    applyPatches();
    // This, again, should not be the job of the module. Goal post for v1.0.0?
    registerPlugins();
    // Create instance of `Server : Thread`, start thread, return instance.
    gICPServer = Server.bootstrap();
}

void run() {
    try {
        prelude();

        for (;;) {
            gTrackerManager.checkActivity();
            Thread.sleep(dur!"msecs"(300));
        }

        // Any cleanup here.
        fclose(stdout.getFP);
        fclose(stderr.getFP);
    } catch (Exception ex) {
        writeln(ex.msg ~ " " ~ ex.file ~ " " ~ ex.line.to!string);
    }
}

extern (Windows) BOOL DllMain(HMODULE module_, uint reason, void*) { // @suppress(dscanner.style.phobos_naming_convention) {
    if (reason == DLL_PROCESS_ATTACH) {
        Runtime.initialize();
        new Thread({ run(); }).start();
    }
    else if (reason == DLL_PROCESS_DETACH) {
        Runtime.terminate();
        FreeLibrary(module_);
    }
    return TRUE;
}
