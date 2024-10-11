import core.sys.windows.dll;

import std.stdio;
import core.runtime;
import core.sys.windows.windows;

import jagex;
import comms.server;

void run(HMODULE hModule) {
    freopen("C:\\ProgramData\\Jagex\\launcher\\runedoc.log", "w", stdout.getFP);
    freopen("C:\\ProgramData\\Jagex\\launcher\\runedoc.log", "w", stderr.getFP);


    JagexHooks jagexHooks = new JagexHooks();
    jagexHooks.placeAll();

    Server server = new Server();
    server.start();

    for (;;) {
        if (server.needsRestart) {
            server = new Server();
            server.start();
        }

        Thread.sleep(dur!"msecs"(20));
    }

    fclose(stdout.getFP);
    fclose(stderr.getFP);
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
