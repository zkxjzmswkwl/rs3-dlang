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
import plugins;
import std.concurrency;
import core.sync.mutex;


class Server : Thread {
    private string host;
    private ushort port;
    private PacketManager packetManager;
    private PluginManager pluginManager;
    private string[] packetQueue;
    private Mutex packetQueueMutex;

    private bool hasClient;
    // private Socket client;
    public bool needsRestart;

    @disable this();

    this(string host, ushort port) {
        super(&run);

        this.host = host;
        this.port = port;

        hasClient    = false;
        needsRestart = false;

        packetManager    = Context.get().packetManager();
        pluginManager    = PluginManager.get();
        packetQueueMutex = new Mutex();
    }

    private void queuePacket(string packet) {
        synchronized(packetQueueMutex) {
            packetQueue ~= packet;
        }
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

    private void processRequest(Socket client, string[] packet) {
        auto cmd = packet[1];

        auto packets = packetManager.packetMap;
        if (packets[cmd] is null) {
            warn("Packet not found: " ~ cmd);
            return;
        }

        string outBuffer;
        if (packet.length > 1) {
            outBuffer = packets[cmd].getBuffer(packet[2..$]);
        }
        queuePacket(outBuffer);
    }

    private void processPacket(Socket client, string packet) {
        if (packet == "1" || !canFind(packet, ":")) {
            return;
        }
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
                scope (exit)    processPacket(client, dongSpl);
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
            queuePacket("ack");
        } else if (canFind(packet, "req:")) {
            this.processRequest(client, spl);
            // Don't need ack, packets prefixed with `req:` are _requests,
            // meaning the server is intended to send data back regardless.
        } else if (canFind(packet, "_specpl_")) {
            if (pluginManager.plugins[spl[1]] is null) {
                warn("Packet received for plugin that does not exist: " ~ spl[1]);
                return;
            }

            auto plugin = pluginManager.plugins[spl[1]];
            auto resp = plugin.onPacketRecv(spl);
            queuePacket("_specpl_:" ~ plugin.name ~ ":" ~ resp);
        }
    }

    private void processReceived(Socket client, string buffer) {
		writeln(buffer);
		if (canFind(buffer, "req:")) {
            auto rsn = Context.get().client().getLocalPlayer().getName();
            queuePacket("rsn:"~rsn);
		}
    }

    private void run() {
        auto tcpSocket = new TcpSocket(AddressFamily.INET);
        tcpSocket.blocking = false;
        SocketSet readSet = new SocketSet();
        Socket[] clients;

        try {
            tcpSocket.setOption(SocketOptionLevel.SOCKET, SocketOption.TCP_NODELAY, 1);
        } catch (Exception ex) {
            info(ex.msg);
        }

        tcpSocket.bind(new InternetAddress(this.host, this.port));
        tcpSocket.listen(10);

        info("[>] START | " ~ this.host ~ ":" ~ this.port.to!string);

        while (true) {
            readSet.reset();
            readSet.add(tcpSocket);

            foreach (client; clients) {
                readSet.add(client);
            }

            int readableClients = Socket.select(readSet, null, null);
            if (readableClients) {
                foreach (i, client; clients) {
                    if (readSet.isSet(client)) {
                        try {
                            char[1024] buffer;
                            auto r = client.receive(buffer);
                            if (r == 0 || r == Socket.ERROR) {
                                clients = clients.remove(i);
                                info("Removing disconnected client at index " ~ i.to!string);
                                continue;
                            }
                            processPacket(client, buffer[0..r].to!string);

                        } catch (Exception ex) {
                            info(ex.msg);
                        }
                    }
                }

                if (readSet.isSet(tcpSocket)) {
                    auto newClient = tcpSocket.accept();
                    clients ~= newClient;
                }

                if (packetQueue.length <= 0)    continue;

                synchronized (packetQueueMutex) {
                    foreach (client; clients) {
                        foreach (packet; packetQueue) {
                            client.send(packet);
                        }
                        packetQueue = [];
                    }
                }
            }
        }
    }
}
