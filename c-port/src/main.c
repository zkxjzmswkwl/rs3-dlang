#include <handleapi.h>
#include <libloaderapi.h>
#include <processthreadsapi.h>
#include <Windows.h>
#include <winternl.h>
#include <stdio.h>

#include "common.h"
#include "debug.h"

typedef NTSTATUS (NTAPI *pNtSetInformationThread)(HANDLE, UINT, PVOID, ULONG);

BOOL initialize() {
	// Hooks
	//
	// Shared memory
	//
	// Debug console
#ifdef DEBUG_LOG
	AllocConsole();
	freopen("CONOUT$", "w", stdout);
#endif

#ifndef DEBUG_LOG
	// Hide thread for fun
	HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
	HANDLE hNtsit = GetProcAddress(hNtdll, "NtSetInformationThread");
	pNtSetInformationThread NtSetInformationThread = (pNtSetInformationThread)hNtsit;
	NtSetInformationThread(GetCurrentThread(), 0x11, NULL, 0);
#endif

	return TRUE;
}

BOOL uninitialize(HMODULE hModule) {
#ifdef DEBUG_LOG
	FreeConsole();
#endif
	FreeLibraryAndExitThread(hModule, 0);
	return TRUE;
}

uint64_t entry(HMODULE hModule) {
	if (!initialize()) {
		mbox_error("Failed to initialize. Exiting. Client might crash.");
		uninitialize(hModule);
	}

	uninitialize(hModule);
	return 0;
}

BOOL DllMain(HMODULE hModule, DWORD dwReason, LPVOID lpReserved) { 
	if (dwReason == DLL_PROCESS_ATTACH) {
		HANDLE hThread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)entry, hModule, 0, NULL);
		CloseHandle(hThread);
	}
	return TRUE;
}
