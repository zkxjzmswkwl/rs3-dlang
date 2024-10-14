module tracker.tracker;

import core.thread;
import std.datetime.stopwatch;
import std.format;
import std.conv : to;

import slf4d;

import rdconstants;
import jagex.client;
import jagex.constants;

struct ExpSnapshot {
    uint xp;
    long timestamp;
}

class Tracker : Thread {
    private Skill skill;

    private bool shouldRun;
    private bool active;
    private double hourlyXp;

    private StopWatch stopwatch;
    private ExpSnapshot firstSnapshot;
    private ExpSnapshot lastSnapshot;

    this(Skill skill) {
        this.shouldRun = true;
        this.active = false;

        this.skill = skill;
        super(&run);
    }

    public Skill getSkill() {
        return this.skill;
    }

    @property public bool isActive() {
        return this.active;
    }

    @property public bool isTracking() {
        return this.shouldRun;
    }

    public Tracker setActive(bool val) {
        this.active = val;
        return this;
    }

    public uint getTotalXpGain() {
        auto total = this.lastSnapshot.xp - this.firstSnapshot.xp;
        return total;
    }

    public double getHourlyXp() {
        return this.hourlyXp;
    }

    private ExpSnapshot newSnapshot() {
        auto skillExp = getSkill(this.skill);
        ExpSnapshot snapshot;
        snapshot.xp = skillExp.xp;
        snapshot.timestamp = this.stopwatch.peek.total!"seconds";
        return snapshot;
    }

    private void updateHourlyXp() {
        auto totalXpGain = this.getTotalXpGain();
        float elapsedHours = cast(float) this.stopwatch.peek.total!"seconds" / 3600.0;
        if (totalXpGain == 0)
            return;

        this.hourlyXp = (this.getTotalXpGain() / elapsedHours);
    }

    private void run() {
        this.stopwatch.start();

        this.firstSnapshot = this.newSnapshot();
        this.lastSnapshot = firstSnapshot;

        while (shouldRun) {
            Thread.sleep(msecs(TRACKER_FREQUENCY));
            this.updateHourlyXp();

            if (this.getSkill(skill).xp != lastSnapshot.xp) {
                this.lastSnapshot = this.newSnapshot();
            } else {
                 auto delta = this.stopwatch.peek.total!"seconds" - this.lastSnapshot.timestamp;
                 // Shit's dead, no longer training this skill.
                 if (delta >= TRACKER_TIMEOUT) {
                    this.shouldRun = false;
                 }
            }
        }
    }

    public string getCommString() {
        auto skillXp = getSkill(this.skill);
        // skillId:level:current:gained:hourly
        return format(
            "%d#%d#%d#%d#%f",
            this.skill,
            skillXp.currentLevel,
            skillXp.xp,
            this.getTotalXpGain(),
            this.getHourlyXp()
        );
    }

    // Small wrapper around the temporary (and dirty) Exfil class
    public static SkillExpTable getSkill(Skill skill) {
        return Exfil.get().getSkillExpTable(skill);
    }
}
