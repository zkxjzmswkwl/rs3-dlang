module jagex.jaghooks;

import kronos.hook;
import util.types;

import jagex.hooks;

// All rs2client specific hooks.
// I don't see a future where this project will involve circumventing
// ClientWatch and thus we won't need a container for WinApi hooks/a base class.
// -
// Hook fn bodies are in hooks.d, this class only manages the Hook instances.
//------------------------------------------------------------------------------ 
class JagexHooks
{
    private Hook npcActionOne;
    private Hook addChatMessage;

    this()
    {
        // TODO: need logging >.<
        // Log ctor for gc related debugging.

        this.npcActionOne = new Hook(0x117550, "npcAction1");
        this.addChatMessage = new Hook(0xCD640, "addChat");
    }

    public JagexHooks placeAll()
    {
        this.npcActionOne.place(&hookNpc1, cast(void**)&npcTrampoline);
        this.addChatMessage.place(&hookAddChat, cast(void**)&chatTrampoline);
        return this;
    }

    public JagexHooks enableAll()
    {
        return this;
    }

    public JagexHooks disableAll()
    {
        return this;
    }
}
