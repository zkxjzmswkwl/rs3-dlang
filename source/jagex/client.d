module jagex.client;

import std.string;
import core.sys.windows.windows;
import slf4d;
import util;
import context;

import jagex.constants;
import jagex.clientobjs;
import kronos.hook;

class Client {
    private Address clientPtr;

    ///
    /// Client objects; typically these are children of jag::Client.
    ///
    private LocalPlayer localPlayer;
    private Inventory inventory;
    private SceneManager sceneManager;
    private Skills skills;
    private Render render;
    private ChatHistory chatHistory;

    this() {
        this.refresh();
        this.unhookMouseHook();
    }

    public void refresh() {
        auto tmp = cast(Address) GetModuleHandle("rs2client.exe") + 0xD89758;
        this.clientPtr = read!Address(tmp);
        this.localPlayer = new LocalPlayer(this.clientPtr);
        this.inventory = new Inventory(this.clientPtr);
        this.skills = new Skills(this.clientPtr);
        this.sceneManager = new SceneManager(this.clientPtr);
        this.render = new Render(this.clientPtr);
        this.chatHistory = new ChatHistory(this.clientPtr);
    }

    // Without this, hitting a breakpoint will cause your mouse to feel as though it's polling at 1hz.
    // NOTE: See https://github.com/zkxjzmswkwl/rs3-dlang/issues/1
    //------------------------------------------------------------------------------------------------ 
    public void unhookMouseHook() {
        HHOOK mouseHook = *cast(HHOOK*)(cast(ulong) GetModuleHandle(NULL) + 0xD7E078);
        if (UnhookWindowsHookEx(mouseHook)) {
            infoF!"Mouse hook unhooked."();
        } else {
            warnF!"Mouse hook not handled, if you hit a breakpoint you're fucked.";
        }
    }

    public ClientState getState() {
        return read!ClientState(this.clientPtr + 0x19F48);
    }

    public LocalPlayer getLocalPlayer() {
        return this.localPlayer;
    }

    public SceneManager getSceneManager() {
        return this.sceneManager;
    }

    public Inventory getInventory() {
        return this.inventory;
    }

    public Render getRender() {
        return this.render;
    }

    public ChatHistory getChatHistory() {
        return this.chatHistory;
    }

    public Address getPtr() {
        return this.clientPtr;
    }
}

struct SkillExpTable
{
    char[0xC] padc; 
    uint xp;
    uint currentLevel;
    uint boostedLevel;
}

// Temp, prob.
// Contains data exfiltrated from hooked functions.
// Set via Context singleton.
// This is a messy approach imo.
class Exfil {
    // Singleton
    __gshared Exfil instance = null;

    public static Exfil get() {
        if (instance is null)
            instance = new Exfil();
        return instance;
    }

    // Exfil
    private Address skillArrayBase = 0x0;

    @property public Address skillArrayBaseLoc() {
        return this.skillArrayBase;
    }

    public void setSkillArrayBase(Address val) {
        this.skillArrayBase = val;
        infoF!"Exfil::skillArrayBase set (%016X)"(val);
    }

    // TODO: Very temporary
    // wanted to test.
    public SkillExpTable getSkillExpTable(Skill skill) {
        if (this.skillArrayBase == 0x0) {
            warn("Skill array base is null.");
            return SkillExpTable.init;
        }

        auto skillOffset = skill * 0x18;
        auto skillBase = this.skillArrayBase + skillOffset;

        return read!SkillExpTable(skillBase);
    }
}
