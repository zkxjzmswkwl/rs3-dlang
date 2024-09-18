module comms.pipes;

import core.sys.windows.windows;
import core.sys.windows.windef;
import std.stdio;
import std.string;
import std.algorithm : canFind;
import std.conv : to;
import core.thread;

import slf4d;

import context;
import jagex.client;
import jagex.constants;
import tracker.tracker;
import tracker.trackermanager;

class NamedPipe : Thread
{
private:
    string pipeName;
    bool hasClient;
    HANDLE hPipe;

    int destroy()
    {
        info("[-] Destroying NamedPipe, closing handle.");
        CloseHandle(this.hPipe);
        return -1;
    }

    void run()
    {
        info("[+] NamedPipes thread started.");
        this.initialize();
        this.acceptClients();

        while (hasClient)
        {
            auto inBuff = this.read();
            info("[/] recv: "~inBuff);

            if (inBuff == "DISC")
            {
                this.hasClient = false;
                this.initialize();
                this.acceptClients();
                continue;
            }

            // TODO: Some sort of command handler
            // This is tmp testing.
            if (!canFind(inBuff, "TRACKER::"))
                continue;

            auto command = inBuff.split("::")[1];
            if (command == "UPDATE")
            {
                // Get all the Tracker objects that are currently active.
                Tracker[] activeTrackers = Context.get().tManager.getActiveTrackers();
                foreach (_tracker; activeTrackers)
                {
                    auto commsStr = _tracker.getCommString();
                    int numReprSkill = cast(int)_tracker.getSkill();
                    this.write("Skill-" ~ to!string(numReprSkill) ~ "\t" ~ commsStr);
                    if (!FlushFileBuffers(this.hPipe))
                        error("FlushFileBuffers failed.");

                    // TODO: 100ms is a tad extreme. Testing.
                    Thread.sleep(dur!"msecs"(100));

                    if (this.read() == "ACK")
                        info("ACK received.");
                }
            }
        }
    }

public:
    this(string pipeName)
    {
        super(&run);
        this.pipeName = pipeName;
        this.hasClient = false;

        info("[+] NamedPipes ctor");
    }

    ~this()
    {
        // Important to understand the lifetime of NamedPipes instances.
        info("[-] NamedPipes dtor");
    }

    // TODO: POC, abstract later.
    void initialize()
    {
        auto pipePath = r"\\.\pipe\" ~ this.pipeName;

        // Bunch of Windows ugliness. Support wstring.
        this.hPipe = CreateNamedPipeW(
            // This might need to be a cast to (wchar*). If shit blows up, start here.
            to!wstring(pipePath).ptr,
            PIPE_ACCESS_DUPLEX,
            PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
            // Might want to lower
            PIPE_UNLIMITED_INSTANCES,
            // out buffer capacity
            512,
            // in buffer capacity
            512,
            0,
            null
        );

        if (this.hPipe == INVALID_HANDLE_VALUE)
        {
            info("Failed to initialize comms pipe.");
            return;
        }
    }

    int acceptClients()
    {
        info("[/] Waiting for client.");

        if (ConnectNamedPipe(this.hPipe, null) == 0)    return this.destroy();

        this.hasClient = true;
        info("[/] Accepted client without issue.");

        return 1;
    }

    bool write(string message)
    {
        // Bunch of Windows ugliness.
        DWORD writeSize;
        BOOL didWrite = WriteFile(
            this.hPipe,
            message.ptr,
            // Only supporting UTF-8 I think.
            cast(DWORD)message.length,
            &writeSize,
            null
        );

        if (!didWrite || writeSize == 0)
        {
            info("Write failure.");
            this.destroy();
            return false;
        }

        return true;
    }

    /// Blocking read
    string read()
    {
        char[512] buffer;
        DWORD len;
        BOOL didRead = ReadFile(
            this.hPipe,
            buffer.ptr,
            512,
            &len,
            null
        );

        if (!didRead)
        {
            auto errorCode = GetLastError();
            infoF!"Read failure %d"(errorCode);
            if (errorCode == ERROR_BROKEN_PIPE)
            {
                info("Broken pipe, client disconnected?");
                this.destroy();
            }
            return "DISC";
        }

        // if not returning an lvalue, e.g
        //   return to!string(buffer[0..len]);
        // we get yelled at. 
        auto str = to!string(buffer[0..len]);
        return str;
    }

}
