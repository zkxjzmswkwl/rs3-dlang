module plugins.pluginmanager;

import jagex.sceneobjs;
import plugins;

class PluginManager {
    private Plugin[string] installedPlugins;

    // Low-lock singleton. Thread safe.
    // After enough accesses, it becomes an incredibly predictable codepath for the cpu.
    // Performance shouldn't be an issue.
    private static bool instantiated_;
    private __gshared PluginManager instance_;
    static PluginManager get() {
        if (!instantiated_) {
            synchronized(PluginManager.classinfo) {
                if (!instance_) {
                    instance_ = new PluginManager();
                }
                instantiated_ = true;
            }
        }
        return instance_;
    }

    public void addPlugin(Plugin plugin) {
        installedPlugins[plugin.name] = plugin;
    }

    public void onUpdateStat(uint** skillPtr, uint newExp) {
        foreach (Plugin plugin; installedPlugins) {
            plugin.onUpdateStat(skillPtr, newExp);
        }
    }

    public void onHighlightEntity(Entity entity, uint highlightVal, char frameCount, float colour) {
        foreach (Plugin plugin; installedPlugins) {
            plugin.onHighlightEntity(entity, highlightVal, frameCount, colour);
        }
    }

    public void onChat(int messageType, string author, string message) {
        foreach (Plugin plugin; installedPlugins) {
            plugin.onChat(messageType, author, message);
        }
    }

    @property public Plugin[string] plugins() {
        return this.installedPlugins;
    }
}