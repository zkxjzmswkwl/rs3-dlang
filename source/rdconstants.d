module rdconstants;

///
/// Seconds, 5 minutes.
///
__gshared const int TRACKER_TIMEOUT = 300;
///
/// 1 Second. 
///
__gshared const int TRACKER_FREQUENCY = 500;
///
/// Should never be changed from 127.0.0.1/localhost.
///
__gshared const string SERVER_IP = "127.0.0.1";
///
/// TODO: Needs to be dynamic if we're to support > 1 client.
///
__gshared const ushort SERVER_PORT = 6969;

__gshared MAX_ADDRESS = 0x7FFFFFFF0000uL;
__gshared MIN_ADDRESS = 0x100000uL;

const ulong CLIENT_PTR           = 0xD89758;
const ulong MOUSE_HOOK           = 0xD7E078;
// Wouldn't rely on this sig.
// 48 89 5C 24 ? 48 89 74 24 ? 48 89 7C 24 ? 55 41 56 41 57 48 8D 6C 24 ? 48 81 EC ? ? ? ? 4C 63 79
const ulong FN_ADD_CHAT          = 0xCE8A0;
// 48 89 5C 24 ? 0F B6 41 ? 4C 8B C9
const ulong FN_UPDATE_STAT       = 0x272980;
// 48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 83 79 ? ? 41 0F B6 F0 8B FA
const ulong FN_HIGHLIGHT_ENTITY  = 0x355300;
// 40 57 48 83 EC ? 48 8B 79 ? 4C 8B D9
const ulong FN_HIGHLIGHT         = 0x1245F0;
// 40 53 48 81 EC ? ? ? ? 48 8B 41 ? 45 8B D9 44 8B 94 24
const ulong FN_RENDER_MENU_ENTRY = 0x418730;
// 48 8B 99 ? ? ? ? 48 3B 99 20 98 01 00 74 24
const ulong FN_SET_CLIENT_STATE  = 0x25A00;
// 44 89 44 24 ? 53 41 55
const ulong FN_RUN_SCRIPT        = 0x8B9E0;
// 40 55 41 54 41 55 41 56 41 57 48 8D AC 24
const ulong FN_ADD_ENTRY_INNER   = 0x14EDA0;

// Client
const ulong OF_CLIENT_STATE     = 0x19F48;
const ulong OF_LOGGED_IN_PLAYER = 0x19F50;
const ulong OF_RENDERER         = 0x199C0;
const ulong OF_SCENE_MANAGER    = 0x19988;
const ulong OF_INVENTORY        = 0x19980;
const ulong OF_SKILL_MANAGER    = 0x198E8;
const ulong OF_CHAT_HISTORY     = 0x19848;
const ulong OF_INTERFACE        = 0x198C8;