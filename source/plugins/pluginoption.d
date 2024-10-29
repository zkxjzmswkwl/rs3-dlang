module plugins.pluginoption;

class PluginOption(T) {
    shared private T value;

    shared this(T value) {
        this.value = cast(shared)value;
    }

    shared public void setValue(T value) {
        this.value = cast(shared)value;
    }

    shared public shared(T) asValue() {
        return value;
    }

    shared public ref shared(T) asRef() {
        return value;
    }
}

class StringOption : PluginOption!string {
    shared this(string value) {
        super(value);
    }
}

class ArrayOption(T) : PluginOption!(T[]) {
    shared this(T[] value) {
        super(value);
    }
}

class IntOption : PluginOption!int {
    shared this(int value) {
        super(value);
    }
}

class BoolOption : PluginOption!bool {
    shared this(bool value) {
        super(value);
    }
}

class FloatOption : PluginOption!float {
    shared this(float value) {
        super(value);
    }
}

class LongOption : PluginOption!long {
    shared this(long value) {
        super(value);
    }
}