module plugins.highlighter.highlighter;

import plugins;
import jagex.sceneobjs;

class Highlighter : Plugin {
    shared this() {
        super("Entity Highlighter", 1.0);
    }

    shared override void onUpdateStat(uint** skillPtr, uint newExp) {
        // Do nothing
    }

    shared override void postUpdateStat(uint** skillPtr, uint newExp) {
        // Do nothing
    }

    shared override void onHighlightEntity(Entity entity, uint highlightVal, char frameCount, float colour) {
        if (entity.getName() == "War") {
            entity.forceHighlight();
            // `Interrupt` exceptions are caught in the hook body.
            // If an `Interrupt` exception is thrown, the hook body will return immediately,
            // never calling the original function.
            throw new Interrupt();
        }
    }

    shared override void postHighlightEntity(Entity entity, uint highlightVal, char frameCount, float colour) {
        // Do nothing
    }
}