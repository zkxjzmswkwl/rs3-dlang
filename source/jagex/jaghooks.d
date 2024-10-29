module jagex.jaghooks;

import core.sys.windows.windows;

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
    private Hook swapBuffers;
    private Hook drawStringInner;
    private Hook renderMenuEntry;
    private Hook runClientScript;

    this() {
        // this.npcGeneral      = new Hook(0x1574D0, "npcGeneral");
        // this.npcActionOne    = new Hook(0x1653B0, "npcAction1");
        // this.nodeActionOne   = new Hook(0x1655E0, "nodeAction1");
        this.addChatMessage  = new Hook(0xCE8D0,  "addChat");
        // 48 89 5C 24 ? 0F B6 41 ? 4C 8B C9
        this.updateStat      = new Hook(0x2729B0, "updateStat");
        this.getInventory    = new Hook(0x2D72B0, "getInventory");
        this.highlightEntity = new Hook(0x355330, "highlightEntity");
        // 40 53 48 81 EC ? ? ? ? 48 8B 41 ? 45 8B D9 44 8B 94 24
        this.drawStringInner = new Hook(/*0x4188B0*/0x3C1520, "drawStringInner");
        this.renderMenuEntry = new Hook(0x14D210, "renderMenuEntry");
        this.runClientScript = new Hook(0x008BA10, "runClientScript");

        auto oglModuleHandle = GetModuleHandle("opengl32.dll");
        auto swapBuffersAddr = cast(Address)GetProcAddress(oglModuleHandle, "wglSwapBuffers");
        this.swapBuffers = new Hook(swapBuffersAddr, "swapBuffers", false);
    }

    public JagexHooks placeAll() {
        // this.npcGeneral.place(&hookNpcGeneral, cast(void**)&npcGeneralTrampoline);
        // this.npcActionOne.place(&hookNpc1, cast(void**)&npcTrampoline);
        // this.nodeActionOne.place(&hookNode1, cast(void**)&nodeTrampoline1);
        this.updateStat.place(&hookUpdateStat, cast(void**)&updateStatTrampoline);
        this.highlightEntity.place(&hookHighlightEntity, cast(void**)&highlightEntityTrampoline);
        // this.drawStringInner.place(&hookDrawStringInner, cast(void**)&drawStringInnerTrampoline);
        // this.renderMenuEntry.place(&hookRenderMenuEntry, cast(void**)&renderMenuEntryTrampoline);
        // this.runClientScript.place(&hookRunClientScript, cast(void**)&runClientScriptTrampoline);
        this.swapBuffers.place(&hookSwapBuffers, cast(void**)&swapBuffersTrampoline);

        this.addChatMessage.place(&hookAddChat, cast(void**)&chatTrampoline);
        // this.getInventory.place(&hookGetInventory, cast(void**)&getInventoryTrampoline);

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
