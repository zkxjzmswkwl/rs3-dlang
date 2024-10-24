module plugins.plugin;

import jagex.sceneobjs;
import jagex.clientobjs;
import context;

class Plugin {
    private string name;
    private double versioning;
    private bool enabled;

    shared this(string name, double versioning) {
        this.name = name;
        this.versioning = versioning;
        this.enabled = false;
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

    // Hopefully they don't get optimized out.
    shared void onChat(int messageType, string author, string message) {}
    shared void onUpdateStat(uint** skillPtr, uint newExp) {}
    shared void postUpdateStat(uint** skillPtr, uint newExp) {}
    shared void onHighlightEntity(Entity entity, uint highlightVal, char frameCount, float colour) {}
    shared void postHighlightEntity(Entity entity, uint highlightVal, char frameCount, float colour) {}

    // TODO:
    // abstract void onDrawMiniMenu();
}