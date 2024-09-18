module tracker.trackermanager;

import std.algorithm;
import std.range;
import std.array;

import slf4d;

import tracker.tracker;
import jagex.constants;


class TrackerManager
{
private:
    Tracker[] skills;

    void makeAllTrackers()
    {
        for (int i = 0; i < 29; i++)
        {
            infoF!"[+] Building tracker for skill %d"(i);
            this.skills[i] = new Tracker(cast(Skill)i);
        }
    }

public:
    this()
    {
        this.skills = new Tracker[29];
        this.makeAllTrackers();
    }

    Tracker[] getActiveTrackers()
    {
        return array(filter!(x => x.isActive)(this.skills));
    }

    Tracker getTracker(T)(T skill)
    {
        return this.skills[cast(int)skill];
    }

    bool isTrackerActive(T)(T skill)
    {
        return this.skills[cast(int)skill].isActive;
    }

    void setTrackerActive(T)(T skill, bool val)
    {
        infoF!"Setting tracker %d active to %s"(skill, val);
        this.skills[cast(int)skill].setActive(val);
    }

    void startTracker(T)(T skill)
    {
        if (this.skills[cast(int)skill].isActive) return;

        this.setTrackerActive(skill, true);
        this.skills[cast(int)skill].start();
    }
}