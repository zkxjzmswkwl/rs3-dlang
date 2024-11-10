module plugins.highlighter.highlighter;

import std.algorithm.searching;
import std.algorithm.iteration;
import std.array;

import plugins;
import jagex.sceneobjs;

class Highlighter : Plugin {
    private string[] targets;

    this() {
        auto manifest = new Manifest();
        manifest
            .withCommand("addEntity", 1, Direction.IN, &addTargetEntityExecutor)
            .withCommand("removeEntity", 1, Direction.IN, &removeTargetEntityExecutor)
            .withCommand("query", 1, Direction.IN, &queryTargetsExecutor);

        super("highlight", manifest, 1.0);
    }

    private string addTargetEntityExecutor(string[] args) {
        targets ~= args[0];
        return "queryresp:" ~ targets.join("^") ~ "^";
    }

    private string removeTargetEntityExecutor(string[] args) {
        targets = targets.filter!(m => m != args[0]).array;
        return "queryresp:" ~ targets.join("^") ~ "^";
    }

    private string queryTargetsExecutor(string[] args) {
        return "queryresp:" ~ targets.join("^") ~ "^";
    }

    override void onHighlightEntity(Entity entity, uint highlightVal, char frameCount, float colour) {
        foreach (target; targets) {
            if (entity.getName() == target) {
                entity.forceHighlight();
                // `Interrupt` exceptions are caught in the hook body.
                // If an `Interrupt` exception is thrown, the hook body will return immediately,
                // never calling the original function.
                throw new Interrupt();
            }
        }
    }
}