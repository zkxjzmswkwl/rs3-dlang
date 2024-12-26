module jagex.engine.patches;

import core.sys.windows.windows;
import util.types;
import util.misc;
import jagex.constants;
import slf4d;


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

// Early returns the function that resets silhouette while doing anything except afking
static void nopSetSilhouette() {
    auto oldProtect = rvaAlterPageAccess(RESET_SILHOUETTE, 1, PAGE_EXECUTE_READWRITE);
    rvaFillBuffer(RESET_SILHOUETTE, [0xC3]);
    rvaAlterPageAccess(RESET_SILHOUETTE, 1, oldProtect);
}

static void nopSetLocalSilhouette() {
    auto oldProtect = rvaAlterPageAccess(SET_SILHOUETTE, SET_LOCAL_PLAYER_SILHOUETTE.length, PAGE_EXECUTE_READWRITE);
    auto firstByte = rvaRead!ubyte(SET_SILHOUETTE);

    if (firstByte == SET_LOCAL_PLAYER_SILHOUETTE[0]) {
        rvaMemset(SET_SILHOUETTE, 0x90, SET_LOCAL_PLAYER_SILHOUETTE.length);
    } else {
        rvaFillBuffer(SET_SILHOUETTE, SET_LOCAL_PLAYER_SILHOUETTE);
    }
    
    rvaAlterPageAccess(SET_SILHOUETTE, SET_LOCAL_PLAYER_SILHOUETTE.length, oldProtect);
}

public static void applyPatches() {
    nopSetSilhouette();
    nopSetLocalSilhouette();
    info("Patches applied.");
}