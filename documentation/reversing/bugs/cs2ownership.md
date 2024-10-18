# CS2 widgets can assume ownership of data they have no right to.

Archaeology material storage is loaded into memory upon 

- Viewing material storage near Arch table
- Inspecting an artefact

The first option results in the container persisting in memory. It's not _just_ persisting in memory as-it-was, it's even updated.

However, if you inspect an artefact, that container is deallocated, requested (packet to server), and finally reallocated. 

Because these windows are constructed entirely with cs2 calls, we can assume that there's an oversight in how the engine perceives lifetimes in relation to cs2 ui calls.