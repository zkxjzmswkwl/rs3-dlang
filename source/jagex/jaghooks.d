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
    private Hook addChatMessage;
    private Hook updateStat;
    private Hook highlightEntity;
    private Hook swapBuffers;
    private Hook renderMenuEntry;
    private Hook runClientScript;
    private Hook highlight;
    private Hook addEntryInner;
    private Hook setClientState;

    this() {
        this.addChatMessage  = new Hook(0xCE8D0,  "addChat");
        // 48 89 5C 24 ? 0F B6 41 ? 4C 8B C9
        this.updateStat      = new Hook(0x2729B0, "updateStat");
        this.highlightEntity = new Hook(0x355330, "highlightEntity");
        // 40 53 48 81 EC ? ? ? ? 48 8B 41 ? 45 8B D9 44 8B 94 24
        this.renderMenuEntry = new Hook(0x14D210, "renderMenuEntry");
        this.runClientScript = new Hook(0x008BA10, "runClientScript");
        this.highlight       = new Hook(0x124620, "highlight");
        this.addEntryInner   = new Hook(0x14edd0, "addEntryInner");
        // 48 8B 99 ? ? ? ? 48 3B 99 20 98 01 00 74 24
        this.setClientState  = new Hook(0x25A00, "setClientState");

        auto oglModuleHandle = GetModuleHandle("opengl32.dll");
        auto swapBuffersAddr = cast(Address)GetProcAddress(oglModuleHandle, "wglSwapBuffers");
        this.swapBuffers = new Hook(swapBuffersAddr, "swapBuffers", false);
    }

    public JagexHooks enableAll() {
        this.updateStat.enable(&hookUpdateStat, cast(void**)&updateStatTrampoline);
        this.highlightEntity.enable(&hookHighlightEntity, cast(void**)&highlightEntityTrampoline);
        // this.renderMenuEntry.place(&hookRenderMenuEntry, cast(void**)&renderMenuEntryTrampoline);
        // this.runClientScript.place(&hookRunClientScript, cast(void**)&runClientScriptTrampoline);
        this.highlight.enable(&hookHighlight, cast(void**)&highlightTrampoline);
        // this.addEntryInner.place(&hookAddEntryInner, cast(void**)&addEntryInnerTrampoline);
        this.swapBuffers.enable(&hookSwapBuffers, cast(void**)&swapBuffersTrampoline);
        this.addChatMessage.enable(&hookAddChat, cast(void**)&chatTrampoline);
        this.setClientState.enable(&hookSetClientState, cast(void**)&setClientStateTrampoline);

        return this;
    }

    public void disableAll() {
        this.addChatMessage.disable();
        this.updateStat.disable();
        this.highlightEntity.disable();
        this.swapBuffers.disable();
        this.renderMenuEntry.disable();
        this.runClientScript.disable();
        this.highlight.disable();
        this.addEntryInner.disable();
    }
}
