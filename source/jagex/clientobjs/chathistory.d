module jagex.clientobjs.chathistory;

import std.algorithm.iteration;
import std.algorithm.searching;
import std.array;

import slf4d;

import util;
import jagex.clientobjs.clientobj;
import jagex.sceneobjs.entity;
import jagex.hooks;
import context;

class ChatHistory : ClientObj {
    private uint CONTAINER_CAPACITY = 0xC0;
    private ulong CONTAINER_START   = 0x8D0;
    private ChatMessage[] messages;

    this(Address clientPtr) {
        super(clientPtr, 0x19848);
        super.logPtr();
        this.messages = [];
    }

    private void populate() {
        // reset previously populated messages array
        this.messages = [];
        // Start @ first pointer to message in container
        auto cursor = CONTAINER_START;
        // Make sure we don't overshoot the container capacity
        while (cursor <= CONTAINER_START + (CONTAINER_CAPACITY * 8)) {
            auto entry = read!Address(this.obj + cursor);
            // The container capacity is really the _max_ capacity, it isn't indicative
            // of currently held size. nullptrs can exist within (CONTAINER_CAPACITY * 8)
            if (entry == 0) break;

            // Build a `ChatMessage` from ptr
            auto message = ChatMessage.fromPointer(entry);
            // Append
            this.messages ~= message;
            cursor += 0x8;
        }
    }

    public ChatMessage[] getMessages() {
        this.populate();
        return this.messages;
    }

    // QoL filtering methods
    public ChatMessage[] getMessageByAuthor(string author) {
        this.populate();
        return this.messages.filter!(msg => msg.author == author).array;
    }

    public ChatMessage[] getMessagesContaining(string substr) {
        this.populate();
        return this.messages.filter!(msg => canFind(msg.message, substr)).array;
    }
}

class ChatMessage {
    string author;
    string message;

    this(string author, string message) {
        this.author = author;
        this.message = message;
    }

    static ChatMessage fromPointer(Address ptr) {
        string _author;
        string _message;
        byte checkAuthor;

        // Really not sure how accurate this will be.
        checkAuthor = read!byte(ptr + 0x3C);
        if (checkAuthor != 0) {
            _author = "GAME";
        } else {
            _author = read!JagString(ptr + 0x40).read();
            // Some messages sent by the game will have a blank author.
            if (_author == "") {
                _author = "GAME";
            }
        }
        // -

        _message = read!JagString(ptr + 0x90).read();
        return new ChatMessage(_author, _message);
    }

    void print() {
        infoF!"%s: %s"(this.author, this.message);
    }
}