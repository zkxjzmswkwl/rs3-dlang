module plugins.manifest;

class Manifest {
    private PluginCommand[string] inCommands;
    private PluginCommand[string] outCommands;

    this() {
        this.inCommands  = new PluginCommand[string];
        this.outCommands = new PluginCommand[string];
    }

    PluginCommand[string] getCommands(Direction direction) {
        return direction == Direction.IN ? this.inCommands : this.outCommands;
    }

    Manifest withCommand(PluginCommand command) {
        if (command.direction == Direction.IN) {
            this.inCommands[command.name] = command;
        } else {
            this.outCommands[command.name] = command;
        }
        return this;
    }

    Manifest withCommand(
        string name,
        int argCount,
        Direction direction,
        string delegate(string[]) executor
    ) {
        auto command = new PluginCommand(name, argCount, direction).withExecutor(executor);
        if (direction == Direction.IN)
            this.inCommands[name] = command;
        else
            this.outCommands[name] = command;
        return this;
    }
}

enum Direction : ubyte {
    IN, OUT 
}

class PluginCommand {
    private string name;
    private Direction direction;
    private uint argCount;
    private string delegate(string[]) run;

    this(string name, int argCount, Direction direction) {
        this.name      = name;
        this.argCount  = argCount;
        this.direction = direction;
    }

    public PluginCommand withDirection(Direction direction) {
        this.direction = direction;
        return this;
    }

    public PluginCommand withName(string name) {
        this.name = name;
        return this;
    }

    public PluginCommand withExecutor(string delegate(string[]) executor) {
        this.run = executor;
        return this;
    }

    public string execute(string[] args) {
        return this.run(args);
    }

    public uint getArgCount() {
        return this.argCount;
    }
}