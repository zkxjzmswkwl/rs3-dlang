module plugins.chatexample.chatexample;

import std.stdio;
import plugins;
import jagex.sceneobjs;

// Logs chat.
class ChatExample : Plugin {
    this() {
        super("chatexample", new Manifest(), 1.0);
    }

    override void onChat(int messageType, string author, string message) {
        writefln("(%d) %s: %s", messageType, author, message);
    }
}