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

__gshared Context instance = null;

class Context
{

    private RuneScape runeScape;
    __gshared private TrackerManager trackerManager;

    private bool debugMode = true;
    private string workingDirectory;
    private string windowsUser;

    private this()
    {
        this.runeScape = new RuneScape();
        this.trackerManager = null;

        // Comically bad
        this.windowsUser = getenv("USERPROFILE").to!string().replace("\\", "/").split("Users/")[1];
        info("Windows user: " ~ this.windowsUser);
        this.workingDirectory = "C:/Users/"~this.windowsUser~"/Documents/de-oppresso-liber/";
        if (exists(this.workingDirectory))
        {
            info("Working directory exists.");
        }
        else
        {
            info("Working directory does not exist. Creating.");
            mkdir(this.workingDirectory);
        }
    }

    public static Context get()
    {
        if (instance is null)
            instance = new Context();
        return instance;
    }

    public RuneScape getRuneScape()
    {
        return this.runeScape;
    }

    @property TrackerManager* tManager()
    {
        return &this.trackerManager;
    }

    public void instantiateTrackerManager()
    {
        if (this.trackerManager is null)
            this.trackerManager = new TrackerManager();
    }

    public bool isDebugMode()
    {
        return this.debugMode;
    }

    public string getWorkingDir()
    {
        return this.workingDirectory;
    }
}
