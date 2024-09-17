module tracker.tracker;

import core.thread;
import std.datetime.stopwatch;

import slf4d;

import jagex.client;
import jagex.constants;

struct ExpSnapshot
{
    uint xp;
    long timestamp;
}

class Tracker : Thread
{
    private bool shouldRun = true;
    // For now let's just track a single skill.
    // Abstract after we have a working prototype.
    private Skill tmpSkill;
    private double hourlyXp;

    private StopWatch stopwatch;
    private ExpSnapshot firstSnapshot;
    private ExpSnapshot lastSnapshot;

    this(Skill skill)
    {
        info("[+] Tracker ctor");

        // tmp
        this.tmpSkill = skill;
    }

    // Important that we understand the lifetime Tracker instances.
    ~this()
    {
        info("[-] Tracker dtor");
    }


    // Small wrapper around the temporary (and dirty) Exfil class
    public static SkillExpTable getSkill(Skill skill)
    {
        return Exfil.get().getSkillExpTable(skill);
    }


    public uint getTotalXpGain()
    {
        return this.lastSnapshot.xp - this.firstSnapshot.xp;
    }

    private ExpSnapshot newSnapshot()
    {
        auto skillExp = getSkill(this.tmpSkill);
        ExpSnapshot snapshot;
        snapshot.xp = skillExp.xp;
        snapshot.timestamp = this.stopwatch.peek.total!"seconds";
        return snapshot;
    }

    private void updateHourlyXp()
    {
        auto totalXpGain = this.getTotalXpGain();
        float elapsedHours = cast(float)this.stopwatch.peek.total!"seconds" / 3600.0;
        if (totalXpGain == 0)
            return;

        this.hourlyXp = (this.getTotalXpGain() / elapsedHours);
    }

    public void run()
    {
        this.stopwatch.start();

        this.firstSnapshot = this.newSnapshot();
        this.lastSnapshot = firstSnapshot;

        infoF!"Tracking skill (%d) with XP: %d"(this.tmpSkill, this.firstSnapshot.xp);

        while (shouldRun)
        {
            this.lastSnapshot = this.newSnapshot();
            this.updateHourlyXp();
            infoF!"[*] Total XP gained in skill (%d) with an hourly rate of (%.8f): %d"(this.tmpSkill, this.hourlyXp, this.getTotalXpGain());
            Thread.sleep(msecs(1000));
        }
    }
}