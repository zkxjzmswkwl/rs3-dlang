module plugins.chatexample.chatexample;

import slf4d;
import plugins;
import jagex.sceneobjs;

// Logs chat.
class ChatExample : Plugin {
    shared this() {
        super("Chat History Example", 1.0);
    }

    shared override void onChat(int messageType, string author, string message) {
        // Log chat.
        infoF!"(%d) %s: %s"(messageType, author, message);
    }
}