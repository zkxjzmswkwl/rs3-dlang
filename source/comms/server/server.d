module comms.server.server;

import slf4d;
import std.stdio;
import std.socket;
import std.string;
import std.conv;
import core.thread;
import core.stdc.string;
import std.algorithm.searching;
import util.misc;
import context;


class Server : Thread {
    private bool shouldRestart;

    this() {
        super(&this.run);

        shouldRestart = false;
    }

    private void processCommand(Socket clientSocket, string[] packet) {
        string cmd = packet[1];
        auto params = packet[2..$];

        switch (cmd) {
            default: break;
            case "red": {
                rvaWrite!uint(0xB63B74, params[0].to!uint);
            } break;
            case "green": {
                rvaWrite!uint(0xB63B74 + 4, params[0].to!uint);
            } break;
            case "blue": {
                rvaWrite!uint(0xB63B74 + 8, params[0].to!uint);
            } break;
        }
    }

    private void processPacket(Socket clientSocket, string packet) {
        // Each incoming packet is suffixed with "<dongs>".
        // Sometimes, one read will yield what was intended to be multiple packets.
        // So, we check for the suffix and if anything is after it, we process the rest as a separate packet.
        auto dongIndex = packet.indexOf("<dongs>");
        if (dongIndex != -1) {
            auto dongSpl = packet.split("<dongs>")[1].to!string;
            if (dongSpl.length > 1) {
                scope (exit)    processPacket(clientSocket, dongSpl);
            }
        }

        string[] spl;
        if (dongIndex == -1) {
            spl = packet.split(":");
        } else {
            spl = packet[0..dongIndex].split(":");
        }

        if (canFind(packet, "cmd:")) {
            this.processCommand(clientSocket, spl);
            clientSocket.send("ack");
        }
    }

    private void run() {
        try {
            info("Starting server...");
            auto serverSocket = new TcpSocket();
            serverSocket.bind(new InternetAddress("localhost", 6968));
            serverSocket.blocking = true;
            serverSocket.listen(500);

            auto clientSocket = serverSocket.accept();
            info("Client connected!");

            scope (exit) {
                clientSocket.close();
                serverSocket.close();
                shouldRestart = true;
            }

            while (true) {
                ubyte[1024] buffer;
                auto bytesRead = clientSocket.receive(buffer);
                if (bytesRead > 0) {
                    string recvBuffer = cast(string) buffer[0..bytesRead];

                    synchronized {
                        info(recvBuffer);
                    }

                    if (recvBuffer == "exit") {
                        info("Exiting server loop.");
                        break;
                    }

                    if (recvBuffer == "getRsn") {
                        auto rsn = Context.get().client().getLocalPlayer.getName();
                        clientSocket.send("rsn:"~rsn);
                    }

                    processPacket(clientSocket, recvBuffer);
                } else {
                    info("bytesRead <= 0.");
                    break;
                }
            }
        } catch (Exception e) {
            error(e.msg);
        }

        info("Client disconnected!");
    }

    @property public bool needsRestart() {
        return this.shouldRestart;
    }
}