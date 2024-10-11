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
    this() {
        super(&this.run);
    }

    private void processCommand(string packet) {
        auto spl = packet.split(":");
        string cmd = to!string(spl[1]);
        auto params = spl[2..$];

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

    private void processPacket(string packet) {
        auto spl = packet.split(":");

        if (canFind(packet, "cmd:")) {
            this.processCommand(packet);
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
            }

            while (clientSocket.isAlive) {
                ubyte[1024] buffer;
                auto bytesRead = clientSocket.receive(buffer);
                if (bytesRead > 0) {
                    string recvBuffer = cast(string) buffer[0..bytesRead];
                    if (recvBuffer == "exit") {
                        info("Exiting server loop.");
                        break;
                    }

                    if (recvBuffer == "getRsn") {
                        auto rsn = Context.get().client().getLocalPlayer.getName();
                        clientSocket.send("rsn:"~rsn);
                    }

                    processPacket(recvBuffer);
                }
            }
        } catch (Exception e) {
            error(e.msg);
        }

            // if (recvBuffer == "yellow") {
            //     rvaWrite!uint(0xB63B74, 1065353216);
            //     rvaWrite!uint(0xB63B74 + 0x4, 1065353216);
            //     rvaWrite!uint(0xB63B74 + 0x8, 1045353216);
            // } else if (recvBuffer == "black") {
            //     rvaWrite!uint(0xB63B74, 1045353216);
            //     rvaWrite!uint(0xB63B74 + 0x4, 1045353216);
            //     rvaWrite!uint(0xB63B74 + 0x8, 1045353216);
            // }

        info("Client disconnected!");
        this.run();
    }
}