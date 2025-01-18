#ifndef COMMON_H
#define COMMON_H

#include <stdint.h>
#include <Windows.h>


void mbox_error(const char* msg) {
	MessageBoxA(NULL, "939-2", msg, 0);
}

#endif
