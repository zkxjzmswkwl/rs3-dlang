# What is this?
It's a side-side-side project. The idea is that RuneMetrics being paid is in direct violation of the [Geneva Convention](https://en.wikipedia.org/wiki/Geneva_Conventions). In addition to *some* xp tracking capabilities, things like filtering/logging chat messages are also currently supported.

It's important to note that the tracking capabilities will never supercede Runemetrics. I'd like to say it's due to me not wanting to get jaggy aggro, but realistically, I just don't want to do all that work.

In all seriousness, this project came to exist almost entirely because there is no **good** way to filter this message:
> Ability not ready yet.

Everything else is kind of auxiliary.

# What's the status?
Very early development. We'll see how the jaggy aggro goes.

# What this is not
- a bot
- a way to cheat
- - The game is already so easy

### Quest Helper?
Porting things like Quest Helper won't be too hard, given that the games are largely the same. That being said, it's still tedious. Testing especially.

### Sharing UI layouts
This is easy and will be included. In all likelihood, I'll provide a separate project to do **just** this and **nothing** else.

The process (in my head) of sharing a UI layout would be something like:
- Person A will surely read through the code to make sure there's nothing malicious, since they're a responsible gamer!
- After Person A has deemed the project **safe to run**, they will do so and click _"Get Shareable UI Code"_.
- Person A will then send the produced code to Person B.
- Person B will surely read through the code to make sure there's nothing malicious, since they're a responsible gamer!
- After Person B has deemed the project **safe to run**, they will do so and click _"Import Shareable UI Code"_.
- Person B will then paste the code they received from Person A into an input box and press `Enter`.
- Job done.

### Ability tracker for streamers etc
It's become increasingly frustrating watching the community employ resource-intensive computer-vision approaches to do this.

This is compounded by the fact that *nobody* seems to realize that obs has a websocket interface in which there's a feature that returns a copy of the obs scene screen buffer.

So what ends up happening is:
- Developer wants to make a sick tool for streamers to track abilities and show them on screen
- Developer realizes _"Holy shit this sucks I have to take screenshots constantly then analyze the pixels, submat against icons, AHHH!!!"_
- - Or the developer will ask the streamer to input **every. single. key.** into an interface and then match those keys with an ability.
- - The developer will then place a low level keyboard hook and do things that way.
- - Then the streamer decides to end stream and play something else, say, Valorant, COD, whatever.
- - That low level keyboard hook from an unsigned program is still running and now that streamer is banned from the game they just opened.
- - Voila! Magic!