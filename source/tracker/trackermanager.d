module tracker.trackermanager;

import std.stdio;
import std.algorithm;
import std.range;
import std.array;

import slf4d;

import tracker.tracker;
import jagex.constants;


class TrackerManager {
private:
    Tracker[] skills;

    void makeAllTrackers() {
        for (int i = 0; i < 29; i++) {
            this.skills[i] = new Tracker(cast(Skill)i);
        }
    }

public:
    this() {
        this.skills = new Tracker[29];
        this.makeAllTrackers();
    }

    void checkActivity() {
        foreach (tracker; this.getActiveTrackers()) {
            if (tracker.isActive && !tracker.isTracking) {
                writefln("Joining tracker for skill %s", tracker.getSkill());
                tracker.join();
                // New object, not started. Does nothing, holds < 50b of data.
                skills[cast(int)tracker.getSkill()] = new Tracker(tracker.getSkill());
            }
        }
    }

    Tracker[] getActiveTrackers() {
        return array(filter!(x => x.isActive)(this.skills));
    }

    Tracker getTracker(T)(T skill) {
        return this.skills[cast(int)skill];
    }

    bool isTrackerActive(T)(T skill) {
        return this.skills[cast(int)skill].isActive;
    }

    void setTrackerStatus(T)(T skill, bool val) {
        getTracker(skill).setActive(val);
    }

    void startTracker(T)(T skill) {
        auto givenTracker = getTracker(skill);
        if (givenTracker.isActive) return;

        this.setTrackerStatus(skill, true);
        givenTracker.start();
    }
}