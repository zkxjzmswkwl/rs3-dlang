module tracker.tracker;

import core.thread;
import std.datetime.stopwatch;
import std.conv : to;

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
    private Skill skill;

    private bool shouldRun;
    private bool active;
    private double hourlyXp;

    private StopWatch stopwatch;
    private ExpSnapshot firstSnapshot;
    private ExpSnapshot lastSnapshot;

    this(Skill skill)
    {
        this.shouldRun = true;
        this.active = false;

        this.skill = skill;
        super(&run);
    }

    // Important that we understand the lifetime of Tracker instances.
    ~this()
    {
        info("[-] Tracker dtor");
    }

    public Skill getSkill()
    {
        return this.skill;
    }

    @property public bool isActive()
    {
        return this.active;
    }

    public Tracker setActive(bool val)
    {
        this.active = val;
        return this;
    }

    public uint getTotalXpGain()
    {
        return this.lastSnapshot.xp - this.firstSnapshot.xp;
    }

    public double getHourlyXp()
    {
        return this.hourlyXp;
    }

    private ExpSnapshot newSnapshot()
    {
        auto skillExp = getSkill(this.skill);
        ExpSnapshot snapshot;
        snapshot.xp = skillExp.xp;
        snapshot.timestamp = this.stopwatch.peek.total!"seconds";
        return snapshot;
    }

    private void updateHourlyXp()
    {
        auto totalXpGain = this.getTotalXpGain();
        float elapsedHours = cast(float) this.stopwatch.peek.total!"seconds" / 3600.0;
        if (totalXpGain == 0)
            return;

        this.hourlyXp = (this.getTotalXpGain() / elapsedHours);
    }

    private void run()
    {
        this.stopwatch.start();

        this.firstSnapshot = this.newSnapshot();
        this.lastSnapshot = firstSnapshot;

        infoF!"Tracking skill (%d) with XP: %d"(this.skill, this.firstSnapshot.xp);

        while (shouldRun)
        {
            this.lastSnapshot = this.newSnapshot();
            this.updateHourlyXp();
            // infoF!"[*] Total XP gained in skill (%d) with an hourly rate of (%.8f): %d"(this.skill, this.hourlyXp, this.getTotalXpGain());
            Thread.sleep(msecs(1000));
        }
    }

    public string getCommString()
    {
        auto skillXp = getSkill(this.skill);
        string str = "";
        str ~= "Gained: " ~ to!string(this.getTotalXpGain());
        str ~= "\tHourly: " ~ to!string(this.getHourlyXp());
        str ~= "\tCurrent: " ~ to!string(skillXp.xp);
        return str;
    }

    // Small wrapper around the temporary (and dirty) Exfil class
    public static SkillExpTable getSkill(Skill skill)
    {
        return Exfil.get().getSkillExpTable(skill);
    }
}
