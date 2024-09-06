module context;

import jagex;

class Context
{
    static Context instance = null;

    private Jagex jagex;

    private this()
    {
        this.jagex = new Jagex();
    }

    public static Context getInstance()
    {
        if (instance is null)
            instance = new Context();
        return instance;
    }

    public Jagex getJagex()
    {
        return this.jagex;
    }
}
