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

        auto oglModuleHandle = GetModuleHandle("opengl32.dll");
        auto swapBuffersAddr = cast(Address)GetProcAddress(oglModuleHandle, "wglSwapBuffers");
        this.swapBuffers = new Hook(swapBuffersAddr, "swapBuffers", false);
    }

    public JagexHooks placeAll() {
        this.updateStat.place(&hookUpdateStat, cast(void**)&updateStatTrampoline);
        this.highlightEntity.place(&hookHighlightEntity, cast(void**)&highlightEntityTrampoline);
        // this.drawStringInner.place(&hookDrawStringInner, cast(void**)&drawStringInnerTrampoline);
        // this.renderMenuEntry.place(&hookRenderMenuEntry, cast(void**)&renderMenuEntryTrampoline);
        // this.runClientScript.place(&hookRunClientScript, cast(void**)&runClientScriptTrampoline);
        this.highlight.place(&hookHighlight, cast(void**)&highlightTrampoline);
        // this.addEntryInner.place(&hookAddEntryInner, cast(void**)&addEntryInnerTrampoline);
        this.swapBuffers.place(&hookSwapBuffers, cast(void**)&swapBuffersTrampoline);
        this.addChatMessage.place(&hookAddChat, cast(void**)&chatTrampoline);

        return this;
    }

    public JagexHooks enableAll() {
        return this;
    }

    public JagexHooks disableAll() {
        return this;
    }
}
