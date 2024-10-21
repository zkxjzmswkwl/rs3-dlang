// Collection of engine functions we call, but don't hook.
module jagex.engine.functions;

import slf4d;

import core.sys.windows.windows;
import std.stdio;
import util;
import jagex.item;
import context;
import jagex.hooks;


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


public static void testDrawShit(immutable(char)* text, int x, int y) {
    auto colour = 0xFFFF0000;
    auto graphics = read!Address(Context.get().client().getPtr() + 0x199C0);
    infoF!"jag::graphics -> %016X"(graphics);
    graphics = read!Address(graphics + 0x40);
    infoF!"jag::graphics -> %016X"(graphics);
    graphics = read!Address(graphics + 8);
    infoF!"jag::graphics -> %016X"(graphics);

    fnCall(drawStringInnerTrampoline, graphics, text, x, y, colour, 255, 2);
}