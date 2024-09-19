module jagex.clientobjs.scenemanager;

import slf4d;

import util.misc;
import util.types;
import jagex.constants;
import jagex.clientobjs.clientobj;
import jagex.sceneobjs.entity;
import jagex.sceneobjs.node;

class SceneManager : ClientObj
{
    this(Address clientPtr)
    {
        // In this case we want client]0x19988]0x58]0x0]0x10130
        super(clientPtr, 0x19988);
        // World vector
        this.obj = read!Address(this.obj + 0x58);
        // Current world is at 0x0 the vast majority of the time.
        // The current world index is located at 0x70.
        this.obj = read!Address(this.obj + 0x0);
        // Linked list of scene objects.
        this.obj = read!Address(this.obj + 0x10130);

        super.logPtr();
    }

    public void recurseGraphNode(Address predicate)
    {
        if (predicate == 0x0)
            predicate = this.obj;

        auto head = read!Address(predicate + 0x168);
        auto end = read!Address(predicate + 0x170);

        if (head == end)
        {
            auto sceneObject = read!Address(predicate + 0x1D0);

            if (sceneObject != 0)
            {
                const ObjectType sceneObjectType = read!ObjectType(sceneObject + 0x10);
                switch (sceneObjectType)
                {
                    case ObjectType.PLAYER:
                    case ObjectType.NPC:
                    {
                        Entity entity = new Entity(sceneObject);
                        // If the NPC has no name we likely don't give a shit about it.
                        // (Or we've misflagged a non-NPC as an NPC)
                        // At which point we also don't give a shit about it.
                        auto entityName = entity.getName();
                        if (entityName.length == 0)
                            break;

                        auto entityPos = entity.getTilePos();
                        infoF!"Entity: %s Lv. %d (%d) [%d, %d]"(entityName, entity.getCombatLevel(), entity.getTotalLevel(), entityPos[0], entityPos[1]);
                        break;
                    }
                    case ObjectType.ZERO:
                    case ObjectType.LOCATION:
                    {
                        // Node node = new Node(sceneObject);
                        // auto nodeName = node.getName();
                        // if (nodeName.length == 0)   break;

                        // auto nodePos = node.getTilePos();
                        // infoF!"Node: %s idx(%d) - [%d, %d]"(nodeName, node.getServerIndex(), nodePos[0], nodePos[1]);
                        break;
                    }
                    default:
                    {
                        break;
                    }
                }
            }
        }
        else
        {
            while (head != end)
            {
                recurseGraphNode(read!Address(head + 0x0));
                head += 0x8;
            }
        }
    }
}