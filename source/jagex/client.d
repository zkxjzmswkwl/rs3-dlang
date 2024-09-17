module jagex.client;

import std.string;
import core.sys.windows.windows;
import slf4d;
import util.types;
import util.misc;
import context;

import jagex.clientobjs.localplayer;
import jagex.clientobjs.inventory;
import jagex.clientobjs.skills;
import jagex.constants;

class Client
{
    private Address clientPtr;

    ///
    /// Client objects; typically these are children of jag::Client.
    ///
    private LocalPlayer localPlayer;
    private Inventory inventory;
    private Skills skills;

    this()
    {
        auto tmp = cast(Address) GetModuleHandle("rs2client.exe") + 0xD829B8;
        this.clientPtr = read!Address(tmp);

        infoF!"Client ptr: %016X"(this.clientPtr);

        if (Context.get().isDebugMode())
        {
            this.unhookMouseHook();
        }

        this.instantiateClientObjects();
    }

    private void instantiateClientObjects()
    {
        info("Instantiating client objects.");

        this.localPlayer = new LocalPlayer(this.clientPtr);
        this.inventory = new Inventory(this.clientPtr);
        this.skills = new Skills(this.clientPtr);
    }

    // Without this, hitting a breakpoint will cause your mouse to feel as though it's polling at 1hz.
    //------------------------------------------------------------------------------------------------ 
    public void unhookMouseHook()
    {
        HHOOK mouseHook = *cast(HHOOK*)(cast(ulong) GetModuleHandle(NULL) + 0xD7CFE8);
        if (UnhookWindowsHookEx(mouseHook))
        {
            infoF!"Mouse hook unhooked."();
        }
        else
        {
            warnF!"Mouse hook not handled, if you hit a breakpoint you're fucked.";
        }
    }

    public ClientState getState()
    {
        return read!ClientState(this.clientPtr + 0x19F48);
    }

    // TODO: Figure out mixin capitalization so we can generate all of our getters ~ [8.14.2024]
    public LocalPlayer getLocalPlayer()
    {
        return this.localPlayer;
    }

    public Inventory getInventory()
    {
        return this.inventory;
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
class Exfil
{
    // Singleton
    __gshared Exfil instance = null;

    public static Exfil get()
    {
        if (instance is null)
            instance = new Exfil();
        return instance;
    }

    // Exfil
    private Address skillArrayBase = 0x0;

    public Address getSkillArrayBase()
    {
        return this.skillArrayBase;
    }

    public void setSkillArrayBase(Address val)
    {
        this.skillArrayBase = val;
        infoF!"Exfil::skillArrayBase set (%016X)"(val);
    }

    // TODO: Very temporary
    // wanted to test.
    public SkillExpTable getSkillExpTable(Skill skill)
    {
        if (this.skillArrayBase == 0x0)
        {
            warn("Skill array base is null.");
            return SkillExpTable.init;
        }

        auto skillOffset = skill * 0x18;
        auto skillBase = this.skillArrayBase + skillOffset;

        return read!SkillExpTable(skillBase);
    }
}
