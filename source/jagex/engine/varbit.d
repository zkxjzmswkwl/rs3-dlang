module jagex.engine.varbit;

import std.string;
import core.sys.windows.windows;

import slf4d;

import util;
import jagex.constants;
import jagex.engine.functions;

class Varbit
{
    private Address clientPtr;

    this()
    {
        // Hack in lieu of place to put this globally.
        // TODO: Global storage
        auto tmp  = cast(Address) GetModuleHandle("rs2client.exe") + 0xD89758;
        this.clientPtr = read!Address(tmp);
    }

    /*
        PlayerVarDomain -> client]0x19f60
        ConfigProvider  -> client]0x18D30


        This is very research-ey. Sorry about that.
        For now, it does the job. As I need the relevant objects,
        they will have their own homes and be resolved elsewhere.
     */
    extern (Windows) private int get(int varbitId)
    {
        Address configProvider = read!Address(this.clientPtr + 0x18D30);
        auto containers = read!(JagArray!Address)(configProvider + 0x98);
        auto group = cast(Address)(containers[69] + 0x38);

        // Fn proto, calls virtual method RVA:0x2A9020 (937-1)
        alias ListShit = extern(Windows) long* function(ulong, int, void**);
        Address sharedPtrAccess = read!Address(group + 0x8);
        Address vTable = read!Address(sharedPtrAccess);

        Address vtfn = read!Address(vTable + 0x38);
        ListShit fnList = cast(ListShit)(vtfn);
        long* varCategory = fnList(sharedPtrAccess, varbitId, null);

        Address* pVarPtr = cast(Address*)(this.clientPtr + 0x19F60);
        infoF!"VarPtr: %016X"(pVarPtr);
        return vTableInvocation!int(pVarPtr, 3, varCategory);
    }

    extern (Windows) private int get(Address* domain, int varbitId)
    {
        Address configProvider = read!Address(this.clientPtr + 0x18D30);
        auto containers = read!(JagArray!Address)(configProvider + 0x98);
        auto group = cast(Address)(containers[69] + 0x38);

        // Fn proto, calls virtual method RVA:0x2A9020 (937-1)
        alias ListShit = extern(Windows) long* function(ulong, int, void**);
        Address sharedPtrAccess = read!Address(group + 0x8);
        Address vTable = read!Address(sharedPtrAccess);

        Address vtfn = read!Address(vTable + 0x38);
        ListShit fnList = cast(ListShit)(vtfn);
        long* varCategory = fnList(sharedPtrAccess, varbitId, null);

        return vTableInvocation!int(domain, 3, varCategory);
    }

    extern (Windows) public int getInv(int inventoryId, int inventorySlot, int varbitId)
    {
        mixin fn!("getInventory", 0x2D72B0, ulong*, int, bool);
        Address* inventoryManager = read!(Address*)(this.clientPtr + 0x19980);

        Address* inventory = cast(Address*)(getInventory(inventoryManager, inventoryId, false));
        auto domains = read!(JagVector!(ForeignObjFixed!(56)))(cast(Address)inventory + 0x28);
        if (domains.empty)  return 0;

        ForeignObjFixed!56 domain = domains.at(inventorySlot);
        int result = get(cast(Address*)&domain, varbitId);
        return result;
    }

    public int getCurrentHealth()
    {
        return this.get(1_668);
    }

    public int getMaxHealth()
    {
        return this.get(24_595);
    }

    public int getSummoningPoints()
    {
        return this.get(41_524);
    }

    public int getPrayerPoints()
    {
        return this.get(16_736);
    }

    public int getScriptureTicks()
    {
        // inv
        return this.get(30_603);
    }

    public int getAggressionPotStatus()
    {
        return this.get(33_448);
    }

    public int getWeaponPoisonStatus()
    {
        return this.get(9_057);
    }

    public int getCharmingPotionStatus()
    {
        return this.get(9_054);
    }

    public int getResidualSoulCount()
    {
        return this.get(11_035);
    }

    public int isDevotionActive()
    {
        return this.get(3_951);
    }

    public int isAnimateDeadActive()
    {
        return this.get(8_758);
    }

    // public int isBerserkerActive()
    // {
    //     // 16766
    //     return this.get(3275);
    // }

    public int isPrayingMelee()
    {
        return this.get(16_747);
    }

    public int isPrayingRetribution()
    {
        return this.get(16_748);
    }

    public int isPrayingRedemption()
    {
        return this.get(16_749);
    }

    public int isPrayingSmite()
    {
        return this.get(16_750);
    }

    public int isPrayingSoulSplit()
    {
        return this.get(16_779);
    }

    /** 
     * Returns: 1 if Ancient Curses prayer book selected, 0 if not.
     */
    public int isUsingCurses()
    {
        return this.get(16_789);
    }

    /** 
     * Returns: 1 if you've opted into Skull, 0 if not.
     */
    public int isOptedIntoPvP()
    {
        return this.get(10_621);
    }
}