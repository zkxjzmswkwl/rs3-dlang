module comms.server.server;

import slf4d;
import std.algorithm;
import std.array;
import std.stdio;
import std.socket;
import std.string;
import std.conv;
import core.thread;
import core.stdc.string;
import std.algorithm.searching;
import util.misc;
import context;
import comms.server.packet;


class Server : Thread
{
    private string host;
    private ushort port;
    private PacketManager packetManager;

    private bool hasClient;
    private Socket client;

    public bool needsRestart = false;

    @disable this();

    this(string host, ushort port)
    {
        super(&run);

        this.host = host;
        this.port = port;

        hasClient = false;

        packetManager = new PacketManager();
        packetManager.initializeAll();
    }

    private void processCommand(string[] packet) {
        string cmd = packet[1];
        auto params = packet[2..$];

        switch (cmd) {
            default: break;
            case "red": {
                rvaWrite!uint(0xB63AC4, params[0].to!uint);
            } break;
            case "green": {
                rvaWrite!uint(0xB63AC4 + 4, params[0].to!uint);
            } break;
            case "blue": {
                rvaWrite!uint(0xB63AC4 + 8, params[0].to!uint);
            } break;
        }
    }

    private void processRequest(string[] packet) {
        auto cmd = packet[1];

        auto packets = packetManager.packetMap();
        if (packets[cmd] is null) {
            warn("Packet not found: " ~ cmd);
            return;
        }

        string outBuffer;
        if (packet.length > 1) {
            outBuffer = packets[cmd].getBuffer(packet[2..$]);
        }
        client.send(outBuffer);
    }

    private void processPacket(string packet) {
        // Each incoming packet is suffixed with "<dongs>".
        // Sometimes, one read will yield what was intended to be multiple packets.
        // So, we check for the suffix and if anything is after it, we process the rest as a separate packet.
        auto dongIndex = packet.indexOf("<dongs>");
        if (dongIndex != -1) {
            auto dongSpl = packet.split("<dongs>")[1].to!string;
            if (dongSpl.length > 1) {
                // scope (exit) lets us ensure packets are still processed in the order they were sent.
                // TCP guarantees that packets are sent and received in order,
                // so we can assume that any data present _after_ `<dongs>` is intended to be the next packet.
                scope (exit)    processPacket(dongSpl);
            }
        }

        string[] spl;
        if (dongIndex == -1) {
            spl = packet.split(":");
        } else {
            spl = packet[0..dongIndex].split(":");
        }

        if (canFind(packet, "cmd:")) {
            this.processCommand(spl);
            client.send("ack");
        } else if (canFind(packet, "req:")) {
            this.processRequest(spl);
            // Don't need ack, packets prefixed with `req:` are _requests,
            // meaning the server is intended to send data back regardless.
        }
    }

    private void processReceived(string buffer)
    {
		writeln(buffer);
		if (canFind(buffer, "req:")) {
            auto rsn = Context.get().client().getLocalPlayer().getName();
			client.send("rsn:"~rsn);
		}
    }

    private void run()
    {
        auto tcpSocket = new TcpSocket(AddressFamily.INET);
        auto address = new InternetAddress(this.host, this.port);

        tcpSocket.bind(address);
        tcpSocket.listen(24);

        info("[>] START | " ~ this.host ~ ":" ~ this.port.to!string);

        while (!hasClient)
        {
            this.client = tcpSocket.accept();
            this.hasClient = true;
            info("[>] JOIN | " ~ client.localAddress.to!string);
			client.send("hello");
        }
        while (hasClient)
        {
            char[1023] buffer;
            auto r = client.receive(buffer);
            if (r > -1)
            {
                try {
                    processPacket(buffer[0..r].to!string);
                } catch (Exception ex) {
                    warn(ex.msg);
                }
            }
			else
			{
				hasClient = false;
                needsRestart = true;
			}
        }

		tcpSocket.close();
		client.close();
    }
}
