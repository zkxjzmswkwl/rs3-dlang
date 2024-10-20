module jagex.jaghooks;

import slf4d;

import jagex;
import kronos.hook;
import util;


// All rs2client specific hooks.
// I don't see a future where this project will involve circumventing
// ClientWatch and thus we won't need a container for WinApi hooks/a base class.
// -
// Hook fn bodies are in hooks.d, this class only manages the Hook instances.
//------------------------------------------------------------------------------ 
class JagexHooks {
    private Hook npcGeneral;
    private Hook npcActionOne;
    private Hook nodeActionOne;
    private Hook addChatMessage;
    private Hook updateStat;
    private Hook getInventory;
    private Hook highlightEntity;

    this() {
        this.npcGeneral      = new Hook(0x1574D0, "npcGeneral");
        this.npcActionOne    = new Hook(0x1653B0, "npcAction1");
        this.nodeActionOne   = new Hook(0x1655E0, "nodeAction1");
        this.addChatMessage  = new Hook(0xCE8D0,  "addChat");
        this.updateStat      = new Hook(0x272EA0, "updateStat");
        this.getInventory    = new Hook(0x2D7360, "getInventory");
        this.highlightEntity = new Hook(0x354EF0, "highlightEntity");

        // this.placeSetForegroundHook();
    }

    public JagexHooks placeAll() {
        this.npcGeneral.place(&hookNpcGeneral, cast(void**)&npcGeneralTrampoline);
        this.npcActionOne.place(&hookNpc1, cast(void**)&npcTrampoline);
        this.nodeActionOne.place(&hookNode1, cast(void**)&nodeTrampoline1);
        // this.addChatMessage.place(&hookAddChat, cast(void**)&chatTrampoline);
        this.updateStat.place(&hookUpdateStat, cast(void**)&updateStatTrampoline);
        // this.getInventory.place(&hookGetInventory, cast(void**)&getInventoryTrampoline);
        this.highlightEntity.place(&hookHighlightEntity, cast(void**)&highlightEntityTrampoline);
        return this;
    }

    /// Not Jagex related, but they call this on afk timer like three fucking times.
    /// Really annoying.
    private void placeSetForegroundHook() {
        auto setForegroundWindow = resolveFunction("user32.dll", "SetForegroundWindow");
        infoF!"SetForegroundWindow: %016X"(setForegroundWindow);
        Hook sfgHook = new Hook(setForegroundWindow, "SetForegroundWindowHook");
        sfgHook.place(&hookSetForegroundWindow, cast(void**)&setForegroundTrampoline);
    }

    public JagexHooks enableAll() {
        return this;
    }

    public JagexHooks disableAll() {
        return this;
    }
}
