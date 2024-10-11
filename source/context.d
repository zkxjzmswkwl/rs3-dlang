module context;

import core.stdc.stdlib;
import std.conv;
import std.array;
import std.file;
import std.algorithm.searching;

import slf4d;

import runescape;
import util.types;
import tracker.trackermanager;
import jagex.client;

__gshared Context instance = null;

class Context  {
    __gshared private TrackerManager trackerManager;

    private Client jagClient;
    private bool debugMode = true;
    private string workingDirectory;
    private string windowsUser;

    private this() {
        this.jagClient = new Client();
        this.trackerManager = null;
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

    @property TrackerManager* tManager() {
        return &this.trackerManager;
    }

    public void instantiateTrackerManager() {
        if (this.trackerManager is null)
            this.trackerManager = new TrackerManager();
    }

    public bool isDebugMode() {
        return this.debugMode;
    }

    public string getWorkingDir() {
        return this.workingDirectory;
    }
}