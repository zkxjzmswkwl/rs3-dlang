module jagex.globals;

import context;
import jagex;
import jagex.clientobjs;
import rd.eventbus;

// ---------------------------------------------------------------------------
// Much more appealing than `Context.get()....` everywhere.
// ---------------------------------------------------------------------------
LocalPlayer ZGetLocalPlayer() {
    return Context.get().client().getLocalPlayer();
}

Render ZGetRender() {
    return Context.get().client().getRender();
}

Client ZGetClient() {
    return Context.get().client();
}

EventBus ZGetBus() {
    return Context.get().getBus();
}