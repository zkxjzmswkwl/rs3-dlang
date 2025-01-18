module context;

import core.sync.mutex;

import core.stdc.stdlib;
import core.sys.windows.windows;
import std.conv;
import std.array;
import std.file;
import std.algorithm.searching;
import jagex.globals;

import slf4d;

import runescape;
import rd.eventbus;
import util;
import tracker.trackermanager;
import jagex.client;
import jagex.engine.varbit;
import jagex.jaghooks;
import comms.server;
import std.concurrency;

__gshared Context instance = null;

// Low-lock synchronized singleton.
// We're in another process' walls, often this is being  accessed from threads that aren't our own.
// Often in hook bodies where we don't decide what arguments are being passed in.
// So, there's a need for a thread-safe solution that gives us access to what we need no matter the context.
// This becomes more performant the more we access it. It becomes a predictable code path quite quickly.
class Context  {
    __gshared private TrackerManager trackerManager;

    private Client jagClient;
    private EventBus eventBus;
    private PacketManager _packetManager;
    private HWND windowHandle;
    private bool debugMode;
    private JagexHooks jagexHooks;
    public HGLRC gameContext = null;
    public HGLRC ourContext  = null;

    private this() {
        this.jagClient = new Client();
        this.jagexHooks = JagexHooks.bootstrap();
        this.eventBus = new EventBus();
        this.eventBus.attach(this.jagClient);
        this._packetManager = new PacketManager();
        this.trackerManager = null;
        this.windowHandle = null;
        this.debugMode = true;
    }

    private static bool instantiated_;
    private __gshared Context instance_;

    static Context get() {
        if (!instantiated_) {
            synchronized(Context.classinfo) {
                if (!instance_) {
                    instance_ = new Context();
                }
                instantiated_ = true;
            }
        }
        return instance_;
    }

    public Client client() {
        return this.jagClient;
    }

    public EventBus getBus() {
        return this.eventBus;
    }
    
    public JagexHooks getJagexHooks() {
        return this.jagexHooks;
    }

    public PacketManager packetManager() {
        return this._packetManager;
    }
    
    @property TrackerManager tManager() {
        if (this.trackerManager is null)
            this.trackerManager = new TrackerManager();
        return this.trackerManager;
    }

    public bool isDebugMode() {
        return this.debugMode;
    }

    public HWND getWindowHandle() {
        return this.windowHandle;
    }

    public Context setWindowHandle(HWND handle) {
        this.windowHandle = handle;
        return this;
    }
}