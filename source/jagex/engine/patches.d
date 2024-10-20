module jagex.engine.patches;

import core.sys.windows.windows;
import util.types;
import util.misc;
import jagex.constants;


static void nopEntityRendering(Address renderCall, ubyte[] originalBytes) {
    auto oldProtect = rvaAlterPageAccess(renderCall, 6, PAGE_EXECUTE_READWRITE);
    auto firstByte = rvaRead!ubyte(renderCall);

    if (firstByte == RENDER_ENTITIES_BYTES[0]) {
        rvaFillBuffer(renderCall, [0x90, 0x90, 0x90, 0x90, 0x90, 0x90]);
    } else {
        rvaFillBuffer(renderCall, originalBytes);
    }
    
    rvaAlterPageAccess(renderCall, 6, oldProtect);
}

static void nopSetEntityHighlighting() {
    auto oldProtect = rvaAlterPageAccess(MOV_ENTITY_HIGHLIGHT, 7, PAGE_EXECUTE_READWRITE);
    auto firstByte = rvaRead!ubyte(MOV_ENTITY_HIGHLIGHT);
    if (firstByte == SET_ENTITY_HIGHLIGHT[0]) {
        rvaFillBuffer(MOV_ENTITY_HIGHLIGHT, [0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90]);
    } else {
        rvaFillBuffer(MOV_ENTITY_HIGHLIGHT, SET_ENTITY_HIGHLIGHT);
    }
    rvaAlterPageAccess(MOV_ENTITY_HIGHLIGHT, 7, oldProtect);
}