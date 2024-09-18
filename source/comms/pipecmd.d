module comms.pipecmd;

class PipeCommand 
{
private:
    string command;
    int argCount;

public:
    this(string command, int argCount)
    {
        this.command = command;
        this.argCount = argCount;
    }

    string getCommand()
    {
        return this.command;
    }
}