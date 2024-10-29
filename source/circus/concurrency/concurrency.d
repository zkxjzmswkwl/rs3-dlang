module circus.concurrency.concurrency;

import core.sync.mutex;


class Lockable(T) {
    private T value;
    private Mutex mutex;

    this(T value) {
        value = value;
        mutex = new Mutex();
    }

    public T asValue() {
        return value;
    }

    public ref T asRef() {
        return value;
    }

    public void set(T value) {
        value = value;
    }

    @property public Mutex lock() {
        return mutex;
    }
}