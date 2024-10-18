module jagex.engine.functions;

import core.sys.windows.windows;
import std.stdio;
import util;
import jagex.item;
import context;

// Collection of engine functions we call, but don't hook.

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
    mixin fn!("getInventory", 0x2D7360, ulong*, int, bool);
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

