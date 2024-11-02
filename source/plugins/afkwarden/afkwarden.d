module plugins.afkwarden.afkwarden;

import std.algorithm.searching;
import std.algorithm.iteration;
import std.array;
import slf4d;
import plugins;
import jagex.sceneobjs;
import comms.server;

class AFKWarden : Plugin {
    private string[] afkMessages;
    private bool shouldAlert;
    private string alertTriggeredBy;

    this() {
        auto manifest = new Manifest();
        manifest
            .withCommand("addWatchedMessage", 1, Direction.IN, &addWatchedMessageExecutor)
            .withCommand("removeWatchedMessage", 1, Direction.IN, &removeWatchedMessageExecutor)
            .withCommand("checkin", 0, Direction.IN, &checkinExecutor);

        super("afkwarden", manifest, 1.0);
        shouldAlert = false;
    }

    private string addWatchedMessageExecutor(string[] args) {
        afkMessages ~= args[0];
        // Send back new list
        return "queryresp:" ~ afkMessages.join("^") ~ "^";
    }

    private string checkinExecutor(string[] args) {
        if (shouldAlert) {
            shouldAlert = false;
            return "playalert:" ~ alertTriggeredBy;
        }
        return "0";
    }

    private string removeWatchedMessageExecutor(string[] args) {
        afkMessages = afkMessages.filter!(m => m != args[0]).array;
        return "queryresp:" ~ afkMessages.join("^") ~ "^";
    }

    override void onChat(int messageType, string author, string message) {
        foreach (string afkMessage; afkMessages) {
            if (canFind(message, afkMessage)) {
                shouldAlert = true;
                alertTriggeredBy = afkMessage;
                break;
            }
        }
    }
}