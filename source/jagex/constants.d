module jagex.constants;

import jagex.clientobjs.skills;

public enum ClientState : int
{
    LOGIN_SCREEN = 10,
    LOBBY = 20,
    IN_GAME = 30,
    WORLD_HOP = 37,
    DISCONNECTING = 40,
}

enum Skill
{
    ATTACK = 0,
    DEFENCE = 1,
    STRENGTH = 2,
    HITPOINTS = 3,
    RANGED = 4,
    PRAYER = 5,
    MAGIC = 6,
    COOKING = 7,
    WOODCUTTING = 8,
    FLETCHING = 9,
    FISHING = 10,
    FIREMAKING = 11,
    CRAFTING = 12,
    SMITHING = 13,
    MINING = 14,
    HERBLORE = 15,
    AGILITY = 16,
    THIEVING = 17,
    SLAYER = 18,
    FARMING = 19,
    RUNECRAFTING = 20,
    HUNTER = 21,
    CONSTRUCTION = 22,
    SUMMONING = 23,
    DUNGEONEERING = 24,
    DIVINATION = 25,
    INVENTION = 26,
    ARCHAEOLOGY = 27,
    NECROMANCY = 28,
}

enum ObjectType : ubyte
{
    ZERO = 0, // ?
    NPC = 1,
    PLAYER = 2,
    GROUND_ITEM = 3,
    ANIMATION = 4,
    TERRAIN = 6,
    COMBINED_LOCATION = 8,
    LOCATION_CONTAINER = 9,
    LOCATION = 12
}

__gshared const uint[] XP_TABLE = [
    0, 83, 174, 276, 388, 512, 650, 801, 969, 1154, 1358, 1584, 1833, 2107, 2411, 2746, 3115, 3523,
    3973, 4470, 5018, 5624, 6291, 7028, 7842, 8740, 9730, 10824, 12031, 13363, 14833, 16456, 18247,
    20224, 22406, 24815, 27473, 30408, 33648, 37224, 41171, 45529, 50339, 55649, 61512, 67983, 75127,
    83014, 91721, 101333, 111945, 123660, 136594, 150872, 166636, 184040, 203254, 224466, 247886,
    273742, 302288, 333804, 368599, 407015, 449428, 496254, 547953, 605032, 668051, 737627, 814445,
    899257, 992895, 1096278, 1210421, 1336443, 1475581, 1629200, 1798808, 1986068, 2192818, 2421087,
    2673114, 2951373, 3258594, 3597792, 3972294, 4385776, 4842295, 5346332, 5902831, 6517253, 7195629,
    7944614, 8771558, 9684577, 10692629, 11805606, 13034431
];

// 48 85 FF 0F 84 ? ? ? ? 48 8B 01 FF 90 ? ? ? ? 84 C0 0F 85
__gshared ulong CALL_RENDER_ENTITIES = 0x311370;
__gshared ulong CALL_RENDER_NPCS     = 0x31A260;
__gshared ulong RESET_SILHOUETTE     = 0x112250;
__gshared ulong SET_SILHOUETTE       = 0x1248AB;
// __gshared ulong MOV_ENTITY_HIGHLIGHT = 0x3552B4;

__gshared ubyte[] RENDER_ENTITIES_BYTES = [0xFF, 0x90, 0x20, 0x01, 0x00, 0x00];
__gshared ubyte[] SET_LOCAL_PLAYER_SILHOUETTE = [
    0x0F, 0xB6, 0x05, 0x3B, 0x98, 0xA3, 0x00, 0xF3, 0x41, 0x0F, 0x11, 0x98, 0x00, 0x01, 0x00, 0x00, 0xF3, 0x41, 0x0F, 0x11, 0xA0, 0x04, 0x01,
    0x00, 0x00, 0xF3, 0x41, 0x0F, 0x11, 0xA8, 0x08, 0x01, 0x00, 0x00, 0xF3, 0x41, 0x0F, 0x11, 0x88, 0x0C, 0x01, 0x00, 0x00, 0xF3, 0x41, 0x0F,
    0x11, 0x90, 0x10, 0x01, 0x00, 0x00, 0xF3, 0x41, 0x0F, 0x11, 0x80, 0x14, 0x01, 0x00, 0x00,
];

// Responsible for setting appropriate entity highlighting value
// __gshared ubyte[] SET_ENTITY_HIGHLIGHT = [0x44, 0x89, 0x99, 0x00, 0x11, 0x00];

//
// OpenGL qol
//
struct _hglrc_ { int unused; }
alias HGLRC = _hglrc_*;

//
// For use with querying buff/debuff bars.
// https://gist.github.com/zkxjzmswkwl/703ec084f1e39ccac377b7f5ab71db82
//
enum Sprite : uint {
    BONFIRE                  = 10931,
    ATTACK_POTION            = 25824,
    STRENGTH_POTION          = 25825,
    DEFENCE_POTION           = 25826,
    MAGIC_POTION             = 25829,
    LIFEPOINT_BOOST          = 25830,
    NECROMANCY_POTION        = 30125,
    PERFECT_JUJU_WOODCUTTING = 163829,
    PERFECT_JUJU_MINING      = 163845,
    PERFECT_JUJU_SMITHING    = 163853,
    PERFECT_JUJU_FISHING     = 166811,
    POWERBURST_ACCELERATION  = 180127,
}