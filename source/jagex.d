module jagex;

class Jagex {
    private byte clientState;
    private string rsn;

    public string getRunescapeName() {
        return this.rsn;
    }

    public byte getClientState() {
        return this.clientState;
    }

    public Jagex setClientState(byte state) {
        this.clientState = state;
        return this;
    }

    public Jagex setRunescapeName(string name) {
        this.rsn = name;
        return this;
    }
}