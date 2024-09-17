module comms.pipes;

import core.sys.windows.windows;
import core.sys.windows.windef;
import std.stdio;
import std.string;
import std.conv : to;
import core.thread;

import slf4d;

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
            if (inBuff == "DISC")
            {
                info("DISC\t");
                this.hasClient = false;
                this.initialize();
                this.acceptClients();
                continue;
            }
            info("[/] recv: "~inBuff);
            this.write("Hell Fire Rage Cocks");
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

        infoF!"[+] Wrote %d bytes to pipe."(writeSize);
        return true;
    }

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
            infoF!"Read filure %d"(errorCode);
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
