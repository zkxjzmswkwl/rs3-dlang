module jagex.globals;

import context;
import jagex;
import jagex.clientobjs;

LocalPlayer ZGetLocalPlayer() {
    return Context.get().client().getLocalPlayer();
}

Render ZGetRender() {
    return Context.get().client().getRender();
}

Client ZGetClient() {
    return Context.get().client();
}
