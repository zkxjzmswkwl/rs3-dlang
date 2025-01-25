module circus.concurrency.threads;

import core.sys.windows.windows;
import core.sys.windows.psapi;
import core.stdc.stdlib;
import std.stdio;
import std.string;

extern (Windows) BOOL Thread32First(HANDLE hSnapshot, THREADENTRY32* lpte);
extern (Windows) BOOL Thread32Next(HANDLE hSnapshot, THREADENTRY32* lpte);

extern (C) int NtQueryInformationThread(
    HANDLE ThreadHandle,
    int ThreadInformationClass,
    void* ThreadInformation,
    uint ThreadInformationLength,
    uint* ReturnLength
);

struct ClientId
{
    void* UniqueProcess;
    void* UniqueThread;
}

struct THREAD_BASIC_INFORMATION
{
    uint ExitStatus;
    void* TebBaseAddress;
    ClientId clientId;
    ulong AffinityMask;
    int Priority;
    int BasePriority;
    void* StartAddress;
}

struct THREADENTRY32
{
    uint dwSize;
    uint cntUsage;
    uint th32ThreadID;
    uint th32OwnerProcessID;
    uint tpBasePri;
    uint tpDeltaPri;
    uint dwFlags;
}

enum TH32CS_SNAPTHREAD = 0x00000004;

/* void findThreadsFromModule(DWORD processID, HMODULE moduleBase) */
/* { */
/*     DWORD snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0); */
/*     if (snapshot == cast(DWORD) INVALID_HANDLE_VALUE) */
/*     { */
/*         writeln("Failed to create thread snapshot."); */
/*         return; */
/*     } */

/*     THREADENTRY32 te32; */
/*     te32.dwSize = THREADENTRY32.sizeof; */

/*     if (!Thread32First(cast(void*) snapshot, &te32)) */
/*     { */
/*         writeln("Failed to enumerate threads."); */
/*         CloseHandle(cast(void*) snapshot); */
/*         return; */
/*     } */

/*     MODULEINFO moduleInfo; */
/*     HANDLE processHandle = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, processID); */
/*     if (!GetModuleInformation(processHandle, moduleBase, &moduleInfo, MODULEINFO.sizeof)) */
/*     { */
/*         writeln("Failed to get module information."); */
/*         CloseHandle(cast(void*) snapshot); */
/*         CloseHandle(processHandle); */
/*         return; */
/*     } */

/*     ulong moduleStart = cast(ulong) moduleInfo.lpBaseOfDll; */
/*     ulong moduleEnd = moduleStart + moduleInfo.SizeOfImage; */

/*     do */
/*     { */
/*         if (te32.th32OwnerProcessID == processID) */
/*         { */
/*             HANDLE threadHandle = OpenThread(THREAD_QUERY_INFORMATION, FALSE, te32.th32ThreadID); */
/*             if (threadHandle) */
/*             { */
/*                 THREAD_BASIC_INFORMATION tbi; */
/*                 if (NtQueryInformationThread(threadHandle, 0, &tbi, THREAD_BASIC_INFORMATION.sizeof, null) == 0) */
/*                 { */
/*                     ulong threadStartAddress = cast(ulong) tbi.StartAddress; */
/*                     if (threadStartAddress >= moduleStart && threadStartAddress < moduleEnd) */
/*                     { */
/*                         writeln("Thread ", te32.th32ThreadID, " originates from module."); */
/*                     } */
/*                 } */
/*                 CloseHandle(threadHandle); */
/*             } */
/*         } */
/*     } */
/*     while (Thread32Next(cast(void*) snapshot, &te32)); */

/*     CloseHandle(cast(void*) snapshot); */
/*     CloseHandle(processHandle); */
/* } */
