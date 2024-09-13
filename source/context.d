module context;

import runescape;
import util.types;

class Context
{
    static Context instance = null;

    private RuneScape runeScape;

    private this()
    {
        this.runeScape = new RuneScape();
    }

    public static Context getInstance()
    {
        if (instance is null)
            instance = new Context();
        return instance;
    }

    public RuneScape getRuneScape()
    {
        return this.runeScape;
    }
}
