module plugins.highlighter.highlighter;

import plugins;
import jagex.sceneobjs;

class Highlighter : Plugin {
    this() {
        super("entityhighlighter", new Manifest(), 1.0);
    }

    override void onHighlightEntity(Entity entity, uint highlightVal, char frameCount, float colour) {
        if (entity.getName() == "War") {
            entity.forceHighlight();
            // `Interrupt` exceptions are caught in the hook body.
            // If an `Interrupt` exception is thrown, the hook body will return immediately,
            // never calling the original function.
            throw new Interrupt();
        }
    }
}