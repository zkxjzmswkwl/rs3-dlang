module context;

import runescape;
import util.types;

class Context
{
    static Context instance = null;

    private RuneScape runeScape;
    private bool debugMode = true;

    private this()
    {
        this.runeScape = new RuneScape();
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

    public bool isDebugMode()
    {
        return this.debugMode;
    }
}
