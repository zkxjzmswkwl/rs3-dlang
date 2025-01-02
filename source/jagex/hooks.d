module jagex.hooks;

import std.stdio;
import std.format;
import std.string;
import std.conv;
import core.sys.windows.windows;

import slf4d;

import rd.eventbus;
import context;
import util.misc;
import util.types;
import jagex.client;
import jagex.sceneobjs;
import jagex.engine.functions;
import jagex.constants;
import plugins;
import jagex.globals;
import opengl.gl3;


///
/// Must be __gshared or shared.
/// If not, we won't be able to call from the game thread, which means we'd always crash in the hook.
///
__gshared Address chatTrampoline;
__gshared Address updateStatTrampoline;
__gshared Address getInventoryTrampoline;
__gshared Address highlightEntityTrampoline;
__gshared Address swapBuffersTrampoline;
__gshared Address renderMenuEntryTrampoline;
__gshared Address runClientScriptTrampoline;
__gshared Address highlightTrampoline;
__gshared Address addEntryInnerTrampoline;
__gshared Address setClientStateTrampoline;

extern (Windows) void hookAddChat(
    void* a1,
    int messageType,
    int a3,
    void* a4,
    JagString* author,
    void* a6,
    void* a7,
    JagString* message,
    void* a9,
    void* a10,
    int a11
)
{
    pragma(inline, false);
    pragma(optimize, false);

    auto pm = PluginManager.get();
    pm.onChat(messageType, author.read(), message.read());

    fnCall(chatTrampoline, a1, messageType, a3, a4, author, a6, a7, message, a9, a10, a11);
}

extern(Windows)
void hookUpdateStat(uint** skillPtr, uint newSkillTotalExp) {
    auto skillId = **skillPtr;
    auto curArrayOffset = skillId * 0x18;
    auto arrayBase = cast(ulong)(skillPtr) - curArrayOffset;

    if (Exfil.get().skillArrayBaseLoc == 0x0) {
        Exfil.get().setSkillArrayBase(arrayBase);
    }

    // We exfiltrate the memory location pointing to an array of skills/their xp from this hook.
    // We wait until that data has been exfiltrated before we can track anything.
    // Overuse of Singletons is an unfortunate side effect of the game thread calling the shots.
    if (!Context.get().tManager.isTrackerActive!uint(skillId)) {
        writefln("Starting tracker thread for skill: %d", skillId);
        Context.get().tManager.startTracker(skillId);
    }

    fnCall(updateStatTrampoline, skillPtr, newSkillTotalExp);
}

extern(Windows)
void hookGetInventory(ulong* rcx, int inventoryId, void* a3) {
    writefln("Inventory ID: %d", inventoryId);
    fnCall(getInventoryTrampoline, rcx, inventoryId, a3);
}

extern(Windows)
void hookHighlightEntity(Address entityPtr, uint highlightVal, char a3, float colour) {
    auto pm = PluginManager.get();
    try {
        pm.onHighlightEntity(new Entity(entityPtr), highlightVal, a3, colour);
    } catch (Interrupt i) {
        return;
    }
    fnCall(highlightEntityTrampoline, entityPtr, highlightVal, a3, colour);
}

// Called at the end of each frame.
// SwapBuffers is responsible for turning the frame.
// `extern(C)` is used to tell the compiler that this function should 
// have the calling convention __stdcall.
extern (C)
void hookSwapBuffers(HDC hDc) {
    auto ctx = ZGetContext();
    
    if (ctx.getWindowHandle() is null) {
        auto window = WindowFromDC(hDc);
        ctx.setWindowHandle(window);
    }

    ctx.gameContext = wglGetCurrentContext();
    if (ctx.ourContext == null) {
        // shared context
        ctx.ourContext = wglCreateContext(hDc);
        wglShareLists(ctx.gameContext, ctx.ourContext);
    }

    if (!wglMakeCurrent(hDc, ctx.ourContext)) {
        return;
    }

    // store gl state
    glPushAttrib(GL_ALL_ATTRIB_BITS);

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();

    // yoink current viewport
    GLint[4] viewport;
    glGetIntegerv(GL_VIEWPORT, viewport.ptr);
    GLint viewportWidth = viewport[2];
    GLint viewportHeight = viewport[3];

    glOrtho(0.0, cast(double)viewportWidth, cast(double)viewportHeight, 0.0, -1.0, 1.0);

    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();

    glViewport(0, 0, viewportWidth, viewportHeight);

    // Actual ui

    // colors
    double[3] windowBodyColor = [0.75, 0.75, 0.75];
    double[3] titleBarColor = [0.49, 0.49, 0.49];
    double[3] borderColorTopLeft = [0.6, 0.6, 0.6];
    double[3] borderColorBottomRight = [0.3, 0.3, 0.3];

    // window sizing
    double windowX = 10.0;
    double windowY = 10.0;
    double windowWidth = 400.0;
    double windowHeight = 400.0;

    // window body
    glColor3d(windowBodyColor[0], windowBodyColor[1], windowBodyColor[2]);
    glBegin(GL_QUADS);
        glVertex2d(windowX, windowY);
        glVertex2d(windowX + windowWidth, windowY);
        glVertex2d(windowX + windowWidth, windowY + windowHeight);
        glVertex2d(windowX, windowY + windowHeight);
    glEnd();

    // title
    double titleBarHeight = 30.0;
    glColor3d(titleBarColor[0], titleBarColor[1], titleBarColor[2]);
    glBegin(GL_QUADS);
        glVertex2d(windowX, windowY);
        glVertex2d(windowX + windowWidth, windowY);
        glVertex2d(windowX + windowWidth, windowY + titleBarHeight);
        glVertex2d(windowX, windowY + titleBarHeight);
    glEnd();

    // top
    glColor3d(borderColorTopLeft[0], borderColorTopLeft[1], borderColorTopLeft[2]);
    glBegin(GL_LINES);
        glVertex2d(windowX, windowY);
        glVertex2d(windowX + windowWidth, windowY);
    glEnd();

    // left 
    glBegin(GL_LINES);
        glVertex2d(windowX, windowY);
        glVertex2d(windowX, windowY + windowHeight);
    glEnd();

    // bottom
    glColor3d(borderColorBottomRight[0], borderColorBottomRight[1], borderColorBottomRight[2]);
    glBegin(GL_LINES);
        glVertex2d(windowX, windowY + windowHeight);
        glVertex2d(windowX + windowWidth, windowY + windowHeight);
    glEnd();

    // right
    glBegin(GL_LINES);
        glVertex2d(windowX + windowWidth, windowY);
        glVertex2d(windowX + windowWidth, windowY + windowHeight);
    glEnd();


    // cleanup
    glFlush();
    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    // restore gl state
    glPopAttrib();

    // pass context back to original
    wglMakeCurrent(hDc, ctx.gameContext);

    // return control flow
    fnCall(swapBuffersTrampoline, hDc);
}


extern(Windows)
void hookRenderMenuEntry(Address* thisptr, ulong index, ulong what) {
    infoF!"RenderMenuEntry: %016X, %016X, %016X"(thisptr, index, what);
    fnCall(renderMenuEntryTrampoline, thisptr, index, what);
}

// Ignore
uint[] blacklistedScripts = [8773, 8298, 10902, 10823, 13824, 1269, 10902, 1652, 8415];
extern(Windows)
void hookRunClientScript(Address* thisptr, Address* script, int a3) {
    auto scriptId = *cast(uint*)script;
    foreach (bs; blacklistedScripts) {
        if (scriptId == bs) {
            goto ret;
        }
    }

    infoF!"RunClientScript: %016X, %d, %d"(thisptr, scriptId, a3);
ret:
    fnCall(runClientScriptTrampoline, thisptr, script, a3);
}

extern(Windows)
void hookHighlight(Address entity, ulong unsure) {
    fnCall(highlightTrampoline, entity, unsure);
}

// 14edd0
extern(Windows)
void hookAddEntryInner(Address* thisptr, void* optionStr, void* objNameStr, void* type, void* idk, void* idk2, void* idk3, void* idk4, void* idk5, void* idk6) {
    infoF!"AddEntryInner: %016X %016X %016X %016X %016X %016X %016X %016X %016X %016X"(thisptr, optionStr, objNameStr, type, idk, idk2, idk3, idk4, idk5, idk6);
    fnCall(addEntryInnerTrampoline, thisptr, optionStr, objNameStr, type, idk, idk2, idk3, idk4, idk5, idk6);
}


import std.variant;

extern(Windows)
void hookSetClientState(ulong* client, int newState) {
    ZGetBus().notify(Event.CLIENT_STATE_CHANGE, Variant(cast(ClientState)newState));
    fnCall(setClientStateTrampoline, client, newState);
}