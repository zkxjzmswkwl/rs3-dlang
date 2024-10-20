module plugins.plugin;

import jagex.sceneobjs;

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

    // Disabled for now
    // abstract void onChat(int messageType, string sender, string message);
    shared abstract void onUpdateStat(uint** skillPtr, uint newExp);
    shared abstract void postUpdateStat(uint** skillPtr, uint newExp);
    shared abstract void onHighlightEntity(Entity entity, uint highlightVal, char frameCount, float colour);
    shared abstract void postHighlightEntity(Entity entity, uint highlightVal, char frameCount, float colour);

    // TODO:
    // abstract void onDrawMiniMenu();
}