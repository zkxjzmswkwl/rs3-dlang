module jagex.jaghooks;

import core.sys.windows.windows;

import slf4d;

import jagex;
import kronos.hook;
import util;
import rdconstants;


// All rs2client specific hooks.
// I don't see a future where this project will involve circumventing
// ClientWatch and thus we won't need a container for WinApi hooks/a base class.
// -
// Hook fn bodies are in hooks.d, this class only manages the Hook instances.
//------------------------------------------------------------------------------ 
class JagexHooks {
    private Hook[] hooks;
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
        this.addChatMessage  = new Hook(FN_ADD_CHAT,         "addChat");
        this.updateStat      = new Hook(FN_UPDATE_STAT,      "updateStat");
        this.highlightEntity = new Hook(FN_HIGHLIGHT_ENTITY, "highlightEntity");
        this.highlight       = new Hook(FN_HIGHLIGHT,        "highlight");
        this.setClientState  = new Hook(FN_SET_CLIENT_STATE, "setClientState");

        // this.renderMenuEntry = new Hook(FN_RENDER_MENU_ENTRY, "renderMenuEntry");
        // this.runClientScript = new Hook(0x8B9E0,  "runClientScript");
        // this.addEntryInner   = new Hook(0x14EDA0, "addEntryInner");

        auto oglModuleHandle = GetModuleHandle("opengl32.dll");
        auto swapBuffersAddr = cast(Address)GetProcAddress(oglModuleHandle, "wglSwapBuffers");
        // this.swapBuffers = new Hook(swapBuffersAddr, "swapBuffers", false);

        this.hooks = [
            this.addChatMessage,
            this.updateStat,
            this.highlightEntity,
            this.highlight,
            this.setClientState,
            // this.swapBuffers,
        ];
    }

    public JagexHooks enableAll() {
        this.updateStat.enable(&hookUpdateStat, cast(void**)&updateStatTrampoline);
        this.highlightEntity.enable(&hookHighlightEntity, cast(void**)&highlightEntityTrampoline);
        // this.highlight.enable(&hookHighlight, cast(void**)&highlightTrampoline);
        // this.swapBuffers.enable(&hookSwapBuffers, cast(void**)&swapBuffersTrampoline);
        this.addChatMessage.enable(&hookAddChat, cast(void**)&chatTrampoline);
        this.setClientState.enable(&hookSetClientState, cast(void**)&setClientStateTrampoline);

        // this.renderMenuEntry.place(&hookRenderMenuEntry, cast(void**)&renderMenuEntryTrampoline);
        // this.runClientScript.place(&hookRunClientScript, cast(void**)&runClientScriptTrampoline);
        // this.addEntryInner.place(&hookAddEntryInner, cast(void**)&addEntryInnerTrampoline);

        return this;
    }

    public void disableAll() {
        // this.swapBuffers.disable();
        this.addChatMessage.disable();
        this.updateStat.disable();
        this.highlightEntity.disable();
        // this.highlight.disable();
        this.setClientState.disable();
    }

    public Hook getSwapBuffers() {
        return this.swapBuffers;
    }

    /*
     * Instantiates `JagexHooks`, enables all hooks and returns the instance.
     */
    public static JagexHooks bootstrap() {
        auto instance = new JagexHooks();
        instance.enableAll();
        return instance;
    }

    public Hook[] toList() {
        return this.hooks;
    }
}
