module kronos.kronos;

import core.sys.windows.windows;
import core.sys.windows.tlhelp32;
import std.stdio;

import kronos.hook;

class Kronos {
    static void freezeThreads(Hook[] hooks) {
        auto threads = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
        THREADENTRY32 entry;
        entry.dwSize = THREADENTRY32.sizeof;

        Thread32First(threads, &entry);
        while (Thread32Next(threads, &entry)) {
            bool sameProcDiffThread = (
                entry.th32OwnerProcessID == GetCurrentProcessId() &&
                entry.th32ThreadID       != GetCurrentThreadId());

            if (sameProcDiffThread) {
                auto thread = OpenThread(/*Likely not needed*/THREAD_ALL_ACCESS, false, entry.th32ThreadID);
                SuspendThread(thread);

                CONTEXT c;
                c.ContextFlags = CONTEXT_CONTROL;
                if (!GetThreadContext(thread,  &c)) {
                    writeln("GetThreadContext failed. Something fucked. cba");
                }

                writefln("Thread %d RIP -> %016X", entry.th32ThreadID, c.Rip);

                // Need to check if RIP pointing to relay page
                SYSTEM_INFO si;
                GetSystemInfo(&si);

                foreach (hook; hooks) {
                    auto pageHead = hook.getAllocatedPage();
                    if (c.Rip >= pageHead && c.Rip < pageHead + si.dwPageSize) {
                        writefln("Thread %d is in relay page for hook %s", entry.th32ThreadID, hook.getName());
                    }
                }

                ResumeThread(thread);
            }
        }
        // CONTEXT threadCtx;
        // threadCtx.ContextFlags = CONTEXT_CONTROL;
        // DWORD64* pIP = &threadCtx.Rip;
        // GetThreadContext(GetCurrentThread(), &threadCtx);
    }
}