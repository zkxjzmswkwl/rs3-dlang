module jagex.clientobjs.scenemanager;

import core.sys.windows.windows;
import core.sys.windows.windef;
import std.algorithm.iteration;
import std.algorithm.searching;
import std.array;
import std.string;
import jagex.engine.functions;

import slf4d;

import util;
import rdconstants;
import jagex.constants;
import jagex.clientobjs.clientobj;
import jagex.sceneobjs;

class SceneManager : ClientObj {
    // TODO: Temp, remove me.
    private int predicateServerIdx;
    private SceneObj[] lastQuery;

    this(Address clientPtr) {
        // In this case we want client]0x19988]0x58]0x0]0x10130
        super(clientPtr, OF_SCENE_MANAGER);
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

        auto head = read!Address(predicate + 0x138);
        auto end = read!Address(predicate + 0x140);

        if (head == end) {
            auto sceneObject = read!Address(predicate + 0x1A0);

            if (sceneObject != 0) {
                const ObjectType sceneObjectType = read!ObjectType(sceneObject + 0x10);
                switch (sceneObjectType) {
                    case ObjectType.PLAYER:
                    case ObjectType.NPC: {
                        SceneObj entity = new Entity(sceneObject);

                        if (searchType == ObjectType.PLAYER || searchType == ObjectType.NPC)
                            lastQuery ~= entity;
                        break;
                    }
                    case ObjectType.ZERO:
                    case ObjectType.LOCATION: {
                        Node node = new Node(sceneObject);
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

    public T[] queryScene(T)(string substr, ObjectType type) {
        lastQuery = [];
        recurseGraphNode(this.update(), type);

        auto filteredQuery = filter!(a => canFind(a.getName(), substr))(lastQuery);
        lastQuery = filteredQuery.array;
        return cast(T[])lastQuery;
    }
}