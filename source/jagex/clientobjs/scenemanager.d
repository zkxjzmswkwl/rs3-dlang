module jagex.clientobjs.scenemanager;

import core.sys.windows.windows;
import core.sys.windows.windef;
import std.string;

import slf4d;

import util;
import jagex.constants;
import jagex.clientobjs.clientobj;
import jagex.sceneobjs;

class SceneManager : ClientObj {
    // TODO: Temp, remove me.
    private int predicateServerIdx;
    private SceneObj[] lastQuery;

    this(Address clientPtr) {
        // In this case we want client]0x19988]0x58]0x0]0x10130
        super(clientPtr, 0x19988);
        this.update();
        // TODO: Temp, remove me.
        this.predicateServerIdx = 0;

        super.logPtr();
    }

    private Address update() {
        this.obj = read!Address(clientPtr + offset);
        this.obj = read!Address(this.obj + 0x58);
        this.obj = read!Address(this.obj + 0x0);
        this.obj = read!Address(this.obj + 0x10130);
        return this.obj;
    }

    public void recurseGraphNode(Address predicate, ObjectType searchType) {
        if (predicate == 0x0) {
            predicate = this.obj;
        }

        auto head = read!Address(predicate + 0x168);
        auto end = read!Address(predicate + 0x170);

        if (head == end) {
            auto sceneObject = read!Address(predicate + 0x1D0);

            if (sceneObject != 0) {
                const ObjectType sceneObjectType = read!ObjectType(sceneObject + 0x10);
                switch (sceneObjectType) {
                    case ObjectType.PLAYER:
                    case ObjectType.NPC: {
                        // Entity entity = new Entity(sceneObject);
                        SceneObj entity = new Entity(sceneObject);
                        // if ( entity.getServerIndex() == this.predicateServerIdx ) {
                        //     string url = "https://runescape.wiki/w/" ~ entity.getName();
                        //     const(char)* urlCStr = toStringz(url);
                        //     ShellExecuteA( NULL, NULL, urlCStr, NULL, NULL, SW_SHOW );
                        //     return;
                        // }
                        // If the NPC has no name we likely don't give a shit about it.
                        // (Or we've misflagged a non-NPC as an NPC)
                        // At which point we also don't give a shit about it.
                        // auto entityName = entity.getName();
                        // if (entityName.length == 0)
                        //     break;

                        // auto entityPos = entity.getTilePos();
                        // infoF!"Entity: %s Lv. %d (%d) [%d, %d]"(entityName, entity.getCombatLevel(), entity.getTotalLevel(), entityPos[0], entityPos[1]);
                        if (searchType == ObjectType.PLAYER || searchType == ObjectType.NPC)
                            lastQuery ~= entity;
                        break;
                    }
                    case ObjectType.ZERO:
                    case ObjectType.LOCATION: {
                        Node node = new Node(sceneObject);
                        // if ( node.getServerIndex() == this.predicateServerIdx ) {
                        //     string url = "https://runescape.wiki/w/" ~ node.getName();
                        //     const(char)* urlCStr = toStringz(url);
                        //     ShellExecuteA( NULL, NULL, urlCStr, NULL, NULL, SW_SHOW );
                        //     return;
                        // }
                        // auto nodeName = node.getName();
                        // if (nodeName.length == 0)   break;

                        // auto nodePos = node.getTilePos();
                        // infoF!"Node: %s idx(%d) - [%d, %d]"(nodeName, node.getServerIndex(), nodePos[0], nodePos[1]);

                        if (searchType == ObjectType.LOCATION || searchType == ObjectType.ZERO)
                            lastQuery ~= node;
                        break;
                    }
                    default: {
                        break;
                    }
                }
            }
        } else {
            while (head != end) {
                recurseGraphNode(*cast(Address*)head, searchType);
                head += 0x8;
            }
        }
    }


    // TODO: Temp, testing, remove this.
    public SceneManager setPredicateIndex(int idx) {
        this.predicateServerIdx = idx;
        return this;
    }

    public void queryScene() {
        // recurseGraphNode(this.update());
    }
    // -

    // TODO: Come back to me later.
    public T[] queryScene(T)(string substr, ObjectType type) {
        lastQuery = [];
        recurseGraphNode(this.update(), type);
        return cast(T[])lastQuery;
    }
}