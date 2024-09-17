This document outlines rough planning for all comms related to the project.

I've decided to not do the following:
- Hooking swapbuffers (Overlay)
- Spawning UI windows from the mapped module

Overlays are simple, easy, and fairly limitless. You have direct access to a rendering API and ImGui is a great plug-n-play solution. That being said, it's a bit played out and I don't think it's the best fit for this particular case.

Spawning UI windows from the mapped module introduces a considerable amount of additional complexity that I'd rather not have in a project that is otherwise fairly simple. I'd rather establish a simple IPC line for a separate project to request data from the module as needed. This lets me separate very annoying and boring frontend UI code. Code which typically contains considerable boilerplate. I like this.

I'm likely to use named pipes, but we'll see.