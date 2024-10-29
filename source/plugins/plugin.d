module plugins.plugin;

import std.uni;
import jagex.sceneobjs;
import jagex.clientobjs;
import comms.server;
import context;
import plugins;

class Plugin {
    public string name;
    private double versioning;
    private bool enabled;
    private Manifest manifest;

    this(string name, Manifest manifest, double versioning) {
        this.name = name;
        this.versioning = versioning;
        this.enabled = false;
        // cast to shared isn't a negative here.
        this.manifest = manifest;
    }

    public void toggle() {
        this.enabled = !this.enabled;
    }
    
    @property public ChatHistory chatHistory() {
        return Context.get().client().getChatHistory();
    }

    @property public SceneManager sceneManager() {
        return Context.get().client().getSceneManager();
    }

    @property public LocalPlayer localPlayer() {
        return Context.get().client().getLocalPlayer();
    }

    protected void registerPacket(string key, Packet packet) {
        Context.get().packetManager().register(key, packet);
    }

    void onChat(int messageType, string author, string message) {}
    void onUpdateStat(uint** skillPtr, uint newExp) {}
    void postUpdateStat(uint** skillPtr, uint newExp) {}
    void onHighlightEntity(Entity entity, uint highlightVal, char frameCount, float colour) {}
    void postHighlightEntity(Entity entity, uint highlightVal, char frameCount, float colour) {}

    import slf4d;
    string onPacketRecv(string[] packet) {
        auto commandName = packet[2];
        bool hasArgs     = packet.length >= 3;
        auto inCommands  = manifest.getCommands(Direction.IN);

        if (auto command = commandName in inCommands) {
            return command.execute(cast(shared)packet[3..$]);
        }

        infoF!"%s: command %s not found."(this.name, commandName);
        return "nil";
    }

    // TODO:
    // abstract void onDrawMiniMenu();
}