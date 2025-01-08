module jagex.clientobjs.inventory;

import slf4d;

import util;
import rdconstants;
import jagex.item;
import jagex.clientobjs.clientobj;
import std.logger.core;

class Inventory : ClientObj {
    this(Address clientPtr) {
        // In this case, we want client]0x19980]0x8]0x18
        super(clientPtr, OF_INVENTORY);
        super.logPtr();
        this.obj = read!Address(this.obj + 0x8);
        this.obj = read!Address(this.obj + 0x18);
        super.logPtr();
    }

    public ItemStack[] getItems() {
        ItemStack[] items = new ItemStack[28];
        uint cursor = 0x0;
        
        while (cursor < 0xDC) {
            auto id = read!uint(this.obj + cursor);
            auto amount = read!uint(this.obj + cursor + 0x4);

            ItemStack itemStack = new ItemStack(new Item(id), amount);
            items[cursor / 0x8] = itemStack;

            cursor += 0x8;
        }
        return items;
    }
}

