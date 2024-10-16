module comms.server.packet;

import slf4d;
import jagex.engine.varbit;
import std.conv;
import context;
import jagex.sceneobjs;
import jagex;
import tracker;

enum PacketType {
    REQUEST,
    COMMAND,
    RESPONSE
}

class Packet {
    private PacketType type;
    private Varbit varbit;

    this(PacketType type, string[] args = []) {
        this.type = type;
        // Bad.
        this.varbit = new Varbit();
    }

    public abstract string getBuffer(string[] args = []);
}

class PacketRespPrayer : Packet {
    this() {
        super(PacketType.RESPONSE);
    }

    public override string getBuffer(string[] args = []) {
        // Prayer, along with some other values, are stored in multiples of 10.
        // Current prayer points being 410, `varbit.getPrayerPoints()` would return 4,100.
        return "resp:prayer:" ~ to!string(varbit.getPrayerPoints() / 10);
    }
}

class PacketRespHealth : Packet {
    this() {
        super(PacketType.RESPONSE);
    }

    public override string getBuffer(string[] args = []) {
        return "resp:health:" ~ varbit.getCurrentHealth().to!string;
    }
}

class PacketRespRsn : Packet {
    this() {
        super(PacketType.RESPONSE);
    }

    public override string getBuffer(string[] args = []) {
        // At some point I need to address the singleton hell.
        // Can't rid of them due to necessity in hooks.
        auto rsn = Context.get().client().getLocalPlayer.getName();
        return "resp:rsn:" ~ rsn;
    }
}

class PacketRespSceneObjects : Packet {
    this() {
        super(PacketType.RESPONSE);
    }

    public override string getBuffer(string[] args = []) {
        string buffer = "resp:sceneobjects:";
        auto sceneManager = Context.get().client().getSceneManager();
        Entity[] entities;

        if (args.length > 0) {
            entities = sceneManager.queryScene!Entity(args[0], ObjectType.NPC);
        } else {
            // Gobbos. every1 loves gobbos
            entities = sceneManager.queryScene!Entity("Goblin", ObjectType.NPC);
        }


        try {
            foreach (entity; entities) {
                buffer ~= entity.asString() ~ "^";
            }
        } catch (Exception ex) {
            info(ex.msg);
        }

        return buffer;
    }
}

class PacketRespNodes : Packet {
    this() {
        super(PacketType.RESPONSE);
    }

    public override string getBuffer(string[] args = []) {
        string buffer = "resp:nodes:";
        auto sceneManager = Context.get().client().getSceneManager();
        Node[] nodes;

        if (args.length > 0) {
            nodes = sceneManager.queryScene!Node(args[0], ObjectType.LOCATION);
        } else {
            nodes = sceneManager.queryScene!Node("", ObjectType.LOCATION);
        }

        try {
            foreach (node; nodes) {
                buffer ~= node.asString() ~ "^";
            }
        } catch (Exception ex) {
            info(ex.msg);
        }

        return buffer;
    }
}


class PacketRespMetrics : Packet {
    this() {
        super(PacketType.RESPONSE);
    }

    public override string getBuffer(string[] args = []) {
        auto trackerManager = Context.get().tManager;
        auto activeTrackers = trackerManager.getActiveTrackers();
        if (activeTrackers.length == 0) {
            return "resp:metrics:none";
        }

        string buffer = "resp:metrics:";

        foreach (tracker; activeTrackers) {
            buffer ~= tracker.getCommString() ~ "^";
        }

        return buffer;
    }
}

/// Unsure if I want to do this or not. We'll see.
class PacketManager {
    // I don't know if this is passed by value or reference.
    // We could by allocating and deallocating this entire structure
    // each time `packetMap()` is called.
    // TODO: Profile
    private Packet[string] packets;

    public void initializeAll() {
        this.packets["prayer"]       = new PacketRespPrayer();
        this.packets["health"]       = new PacketRespHealth();
        this.packets["rsn"]          = new PacketRespRsn();
        this.packets["sceneobjects"] = new PacketRespSceneObjects();
        this.packets["metrics"]      = new PacketRespMetrics();
        this.packets["nodes"]        = new PacketRespNodes();
    }

    @property Packet[string] packetMap() {
        return this.packets;
    }
}
