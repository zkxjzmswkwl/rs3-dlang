module context;

import core.stdc.stdlib;
import core.sys.windows.windows;
import std.conv;
import std.array;
import std.file;
import std.algorithm.searching;

import slf4d;

import runescape;
import util;
import tracker.trackermanager;
import jagex.client;
import jagex.engine.varbit;
import comms.server;
import std.concurrency;

__gshared Context instance = null;

class Context  {
    __gshared private TrackerManager trackerManager;

    private Client jagClient;
    private PacketManager _packetManager;
    private bool debugMode = true;
    private string workingDirectory;
    private string windowsUser;
    private HWND windowHandle;
    private Tid serverThreadId;

    private this() {
        this.jagClient = new Client();
        this._packetManager = new PacketManager();
        this.trackerManager = null;
        this.windowHandle = null;
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

    public string getWorkingDir() {
        return this.workingDirectory;
    }

    public HWND getWindowHandle() {
        return this.windowHandle;
    }

    public Context setWindowHandle(HWND handle) {
        this.windowHandle = handle;
        return this;
    }

    @property public Tid serverTid() {
        return this.serverThreadId;
    }

    @property public void serverTid(Tid tid) {
        this.serverThreadId = tid;
    }
}