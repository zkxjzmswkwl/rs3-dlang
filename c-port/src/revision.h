#ifndef REVISION_H
#define REVISION_H
#include "common.h"

static uint64_t CLIENT_PTR           = 0xD89758;
static uint64_t MOUSE_HOOK           = 0xD7E078;
// Wouldn't rely on this sig.
// 48 89 5C 24 ? 48 89 74 24 ? 48 89 7C 24 ? 55 41 56 41 57 48 8D 6C 24 ? 48 81 EC ? ? ? ? 4C 63 79
static uint64_t FN_ADD_CHAT          = 0xCE8A0;
// 48 89 5C 24 ? 0F B6 41 ? 4C 8B C9
static uint64_t FN_UPDATE_STAT       = 0x272980;
// 48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 83 79 ? ? 41 0F B6 F0 8B FA
static uint64_t FN_HIGHLIGHT_ENTITY  = 0x355300;
// 40 57 48 83 EC ? 48 8B 79 ? 4C 8B D9
static uint64_t FN_HIGHLIGHT         = 0x1245F0;
// 40 53 48 81 EC ? ? ? ? 48 8B 41 ? 45 8B D9 44 8B 94 24
static uint64_t FN_RENDER_MENU_ENTRY = 0x418730;
// 48 8B 99 ? ? ? ? 48 3B 99 20 98 01 00 74 24
static uint64_t FN_SET_CLIENT_STATE  = 0x25A00;
// 44 89 44 24 ? 53 41 55
static uint64_t FN_RUN_SCRIPT        = 0x8B9E0;
// 40 55 41 54 41 55 41 56 41 57 48 8D AC 24
static uint64_t FN_ADD_ENTRY_INNER   = 0x14EDA0;
// 48 89 5C 24 ? 4C 8B 59 ? 44 8D 14 12
static uint64_t FN_GET_INVENTORY     = 0x2D7280;
// 44 88 44 24 ? 89 54 24 ? 56
static uint64_t FN_GET_COMP_BY_ID    = 0x2DFCA0;

// Client
static uint64_t OF_CLIENT_STATE     = 0x19F48;
static uint64_t OF_LOGGED_IN_PLAYER = 0x19F50;
static uint64_t OF_RENDERER         = 0x199C0;
static uint64_t OF_SCENE_MANAGER    = 0x19988;
static uint64_t OF_INVENTORY        = 0x19980;
static uint64_t OF_SKILL_MANAGER    = 0x198E8;
static uint64_t OF_CHAT_HISTORY     = 0x19848;
static uint64_t OF_INTERFACE        = 0x198C8;

#endif
