// Collection of engine functions we call, but don't hook.
module jagex.engine.functions;

import slf4d;

import std.string;
import std.conv : to;
import std.ascii;
import core.sys.windows.windows;
import std.stdio;
import util;
import jagex.item;
import context;
import jagex.hooks;
import jagex.engine.interfacemanager;

// alias Fn = function(ulong*) function(...);

enum InventoryContainer {
    BACKPACK              = 93,
    ARMOUR                = 94,
    BANK                  = 95,
    FAMILIAR              = 530,
    BANK_COIN_POUCH       = 623,
    LOOT_WINDOW           = 787,
    ARCHAEOLOGY_MATERIALS = 885
}

public ItemStack[] getItems(InventoryContainer container) {
    mixin fn!("getInventory", 0x2D72B0, ulong*, int, bool);
    Address* inventoryManager = read!(Address*)(Context.get().client().getPtr() + 0x19980);
    Address inventory = getInventory(inventoryManager, cast(int)container, false);
    writefln("Inventory %d: %016X", cast(int)container, inventory);

    inventory = read!Address(inventory + 0x10);

    ItemStack[] items;
    uint cursor = 0x0;
    while (read!int(inventory + cursor) != -1) {
        auto id = read!int(inventory + cursor);
        auto amount = read!int(inventory + cursor + 0x4);
        if (amount == 0) break;

        auto item = new Item(id);
        items ~= new ItemStack(item, amount);

        cursor += 0x8;
    }

    return items;
}

class RuneTek {

    extern (C++)
    struct Layer {
        /* 0x000 */ ulong* vtable;
        /* 0x008 */ ushort id;
        /* 0x00A */ ushort type;
        /* 0x00C */ ubyte[0x154] __gap00C;
        /* 0x160 */ char[8] text;
        /* 0x168 */ uint spriteId;
        /* 0x16C */ ubyte[0xC] __gap16C;
        /* 0x178 */ JagVector!LayerSlot list;
        /* 0x190 */ ubyte[0x18] __gap190;
        /* 0x1A8 */ JagVector!LayerSlot components;
    }

    extern (C++)
    struct LayerSlot {
        uint __padding000;
        uint __padding004;
        /// smartPtr points to (layer - 0x20).
        void* smartPtr;
        Layer* layer;
    }

    public static ulong getComponent(int id) {
        mixin fn!("getById", 0x2DFCD0, ulong*, int, char);
        auto im = getInterfaceManager();
        auto result = getById(cast(ulong*)(im + 0x20), id, 0);
        return resolvePtrChain(result, [0x8, 0x8, 0x28]);
    }

    public static bool buffbarContains(int spriteId, bool logLayers = false) {
        auto bar = getComponent(284);
        infoF!"BuffBar: %016X"(bar);
        Layer* layer = read!(Layer*)(bar + 0x18);
        for (int j = 0; j < layer.list.size; j++) {
            Layer* dd = layer.list[j].layer;
            for (int z = 0; z < dd.list.size; z++) {
                auto components = dd.list[z].layer.components;

                for (int i = 0; i < components.size; i++) {
                    if (logLayers) {
                        infoF!"Layer: %s, sprite: %d"(fromStringz(components[i].layer.text), components[i].layer.spriteId);
                    }
                    if (components[i].layer.spriteId == spriteId) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
}