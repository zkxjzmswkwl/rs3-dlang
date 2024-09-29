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
    private Hook updateStat;
    private Hook getInventory;

    this()
    {
        this.npcActionOne = new Hook(0x1653B0, "npcAction1");
        this.addChatMessage = new Hook(0xCE8D0, "addChat");
        this.updateStat = new Hook(0x272EA0, "updateStat");
        this.getInventory = new Hook(0x2D7360, "getInventory");
    }

    public JagexHooks placeAll()
    {
        import slf4d;

        this.npcActionOne.place(&hookNpc1, cast(void**)&npcTrampoline);
        this.addChatMessage.place(&hookAddChat, cast(void**)&chatTrampoline);
        this.updateStat.place(&hookUpdateStat, cast(void**)&updateStatTrampoline);
        // this.getInventory.place(&hookGetInventory, cast(void**)&getInventoryTrampoline);

        infoF!"npcTrampoline: %016X"(npcTrampoline);
        infoF!"chatTrampoline: %016X"(chatTrampoline);
        infoF!"updateStatTrampoline: %016X"(updateStatTrampoline);
        // infoF!"getInventoryTrampoline: %016X"(getInventoryTrampoline);

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
