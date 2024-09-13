module runescape;

class RuneScape
{
    private byte clientState;
    private string rsn;

    public string getRunescapeName()
    {
        return this.rsn;
    }

    public byte getClientState()
    {
        return this.clientState;
    }

    public RuneScape setClientState(byte state)
    {
        this.clientState = state;
        return this;
    }

    public RuneScape setRunescapeName(string name)
    {
        this.rsn = name;
        return this;
    }
}
