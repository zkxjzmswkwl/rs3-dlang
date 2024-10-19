import core.sys.windows.dll;

import slf4d;

import std.stdio;
import core.runtime;
import core.sys.windows.windows;

import jagex;
import context;
import tracker;
import util;
import rdconstants;
import comms.server;
import jagex.engine.patches;

Server createServer() {
    Server server = new Server(SERVER_IP, SERVER_PORT);
    server.start();
    return server;
}

void run(HMODULE hModule) {
    try {
        freopen("C:\\ProgramData\\Jagex\\launcher\\runedoc.log", "w", stdout.getFP);
        freopen("C:\\ProgramData\\Jagex\\launcher\\runedoc.log", "w", stderr.getFP);
        infoF!"Client ptr: %016X"(Context.get().client().getPtr());

        TrackerManager trackerManager = Context.get().tManager;

        JagexHooks jagexHooks = new JagexHooks();
        jagexHooks.placeAll();

        Server server = createServer();

        if (Context.get().isDebugMode) {
            info("Operating under debug mode.");
        }

        for (;;) {
            if (server.needsRestart) {
                server.join();
                server = createServer();
            }

            trackerManager.checkActivity();
            Thread.sleep(dur!"msecs"(300));
        }

        fclose(stdout.getFP);
        fclose(stderr.getFP);
    } catch (Exception ex) {
        writeln(ex.msg);
    }
}

extern (Windows) BOOL DllMain(HMODULE module_, uint reason, void*) { // @suppress(dscanner.style.phobos_naming_convention) {
    if (reason == DLL_PROCESS_ATTACH) {
        Runtime.initialize();
        auto t1 = new Thread({ run(module_); }).start();

    }
    else if (reason == DLL_PROCESS_DETACH) {
        Runtime.terminate();
        FreeLibraryAndExitThread(module_, 0);
    }
    return TRUE;
}
