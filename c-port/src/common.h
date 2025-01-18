#ifndef COMMON_H
#define COMMON_H

#include <stdint.h>
#include <Windows.h>

#define THREAD_HIDE_FROM_DEBUGGER 0x11

void mbox_error(const char* msg) { MessageBoxA(NULL, msg, "939-2", 0); }

#endif
