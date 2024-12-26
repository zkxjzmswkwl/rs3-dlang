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
        // Wouldn't rely on this sig.
        // 48 89 5C 24 ? 48 89 74 24 ? 48 89 7C 24 ? 55 41 56 41 57 48 8D 6C 24 ? 48 81 EC ? ? ? ? 4C 63 79
        this.addChatMessage  = new Hook(0xCE8A0,  "addChat");
        // 48 89 5C 24 ? 0F B6 41 ? 4C 8B C9
        this.updateStat      = new Hook(0x272980, "updateStat");
        // 48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 83 79 ? ? 41 0F B6 F0 8B FA
        this.highlightEntity = new Hook(0x355300, "highlightEntity");
        // 40 53 48 81 EC ? ? ? ? 48 8B 41 ? 45 8B D9 44 8B 94 24
        this.renderMenuEntry = new Hook(0x418730, "renderMenuEntry");
        // 44 89 44 24 ? 53 41 55
        // this.runClientScript = new Hook(0x8B9E0,  "runClientScript");
        // 40 57 48 83 EC ? 48 8B 79 ? 4C 8B D9
        this.highlight       = new Hook(0x1245F0, "highlight");
        // 40 55 41 54 41 55 41 56 41 57 48 8D AC 24
        // this.addEntryInner   = new Hook(0x14EDA0, "addEntryInner");
        // 48 8B 99 ? ? ? ? 48 3B 99 20 98 01 00 74 24
        this.setClientState  = new Hook(0x25A00,  "setClientState");

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


    /**************************
     * Instantiates `JagexHooks`, enables all hooks and returns the instance.
     */
    public static JagexHooks bootstrap() {
        auto instance = new JagexHooks();
        instance.enableAll();
        return instance;
    }
}
