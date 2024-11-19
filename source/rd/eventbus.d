module rd.eventbus;

import std.algorithm.searching;
import std.algorithm.iteration;
import std.array;
import circus;
import std.variant;

public enum Event
{
    CLIENT_STATE_CHANGE,
    BACKPACK_CHANGE,
    LOCAL_ANIMATION_CHANGE,
    RENDER_CONTEXT_LOST,
    RENDER_CONTEXT_RESTORED,
    PLAYER_POSITION_CHANGE,
    PLAYER_ORIENTATION_CHANGE,
    MINI_MENU_STATE_CHANGE,
    CHAT_MESSAGE,
    UPDATE_STAT
}

public interface Subject
{
    public void attach(Observer observer);
    public void detach(Observer observer);
    public void notify(Event event, Variant data);
}

public interface Observer
{
    public void update(Event event, Variant data);
}

class EventBus : Subject
{
private:
    Observer[] observers;

public:
    this()
    {
        observers = [];
    }

    void attach(Observer observer)
    {
        observers ~= observer;
    }

    void detach(Observer observer)
    {
        observers = observers.filter!(m => m != observer).array;
    }

    void notify(Event event, Variant data)
    {
        foreach (observer; observers)
        {
            observer.update(event, data);
        }
    }
}