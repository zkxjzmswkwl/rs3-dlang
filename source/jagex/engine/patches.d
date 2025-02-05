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

/// Jagex resets and recalculates the silhouette every single frame.
/// Sometimes, you do need to recalc, because the scene has changed.
/// What's confusing is that they they have one procedure for resetting the silhouette when the scene is unchanged,
/// and a completely separate routine for resetting the silhouette when the scene has changed.
/// This patches the procedure for the non-changed-scene to return immediately.
static void nopSetSilhouette() {
    auto oldProtect = rvaAlterPageAccess(RESET_SILHOUETTE, 1, PAGE_EXECUTE_READWRITE);
    rvaFillBuffer(RESET_SILHOUETTE, [0xC3]);
    rvaAlterPageAccess(RESET_SILHOUETTE, 1, oldProtect);
}

static void nopSetLocalSilhouette() {
    auto oldProtect = rvaAlterPageAccess(SET_SILHOUETTE, SET_LOCAL_PLAYER_SILHOUETTE.length, PAGE_EXECUTE_READWRITE);
    // If the first (or any of the other 60 bytes) is not 0x90 we know it's not patched.
    auto isAlreadyPatched = rvaRead!ubyte(SET_SILHOUETTE) != SET_LOCAL_PLAYER_SILHOUETTE[0];

    if (isAlreadyPatched) {
        rvaFillBuffer(SET_SILHOUETTE, SET_LOCAL_PLAYER_SILHOUETTE);
    } else {
        rvaMemset(SET_SILHOUETTE, 0x90, SET_LOCAL_PLAYER_SILHOUETTE.length);
    }
    
    rvaAlterPageAccess(SET_SILHOUETTE, SET_LOCAL_PLAYER_SILHOUETTE.length, oldProtect);
}

public static void applyPatches() {
    nopSetSilhouette();
    nopSetLocalSilhouette();
    info("Patches applied.");
}