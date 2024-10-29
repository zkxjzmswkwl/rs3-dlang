module plugins.chatexample.chatexample;

import slf4d;
import plugins;
import jagex.sceneobjs;

// Logs chat.
class ChatExample : Plugin {
    this() {
        super("chatexample", new Manifest(), 1.0);
    }

    override void onChat(int messageType, string author, string message) {
        infoF!"(%d) %s: %s"(messageType, author, message);
    }
}