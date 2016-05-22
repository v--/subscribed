/// An event structure representing a one-to-many function/delegate relationship.
module subscribed.event;

import std.traits : isCallable;

///
alias VoidEvent = Event!(void delegate());

/**
 * An event structure representing a one-to-many function/delegate relationship.
 * It mimics a function by overriding the call operator.
 * It also implements the bidirectional range interface.
 *
 * Params:
 *  Type = The listener type this event contains.
 */
struct Event(Type) if (isCallable!Type)
{
    import std.container : DList;
    import std.traits : ReturnTypeTpl = ReturnType, ParameterTypeTuple;
    import std.array : array;

    /// The listeners' type.
    alias ListenerType = Type;

    version (D_Ddoc)
    {
        /// The event's return type.
        alias ReturnType = void;
    }
    else
    {
        static if (is(ReturnTypeTpl!Type == void))
            alias ReturnType = void;
        else
            alias ReturnType = ReturnTypeTpl!Type[];
    }

    /// The event's argument type tuple.
    alias ParamTypes = ParameterTypeTuple!Type;

    private
    {
        DList!(Type) _listeners;
        int _size;
    }

    /// The number of listeners.
    @safe @nogc @property size() const
    {
        return _size;
    }

    /// A dynamic array of all the listeners.
    @safe @property listeners()
    {
        return array(_listeners);
    }

    /**
     * A boolean property indicating whether there are listeners.
     * Part of the bidirectional range interface.
     */
    @safe @nogc @property empty() const
    {
        return _listeners.empty;
    }

    /**
     * The listener in the front.
     * Part of the bidirectional range interface.
     */
    @safe @property Type front() const
    {
        if (empty) return null;
        return _listeners.front;
    }

    /**
     * The listener in the back.
     * Part of the bidirectional range interface.
     */
    @safe @property Type back() const
    {
        if (empty) return null;
        return _listeners.back;
    }

    ~this()
    {
        _listeners.destroy();
    }

    /**
     * Clears all listeners.
     */
    @safe void clear()
    {
        _size = 0;
        _listeners.clear;
    }

    /**
     * Calls all the registered listeners in order.
     *
     * Params:
     *  params = The param tuple to call the listener with.
     *
     * Returns:
     *  An array of results from the listeners.
     *  If $(DDOC_PSYMBOL ReturnType) is void, then this function also returns void.
     */
    ReturnType call(ParamTypes params)
    {
        static if (is(ReturnType == void))
        {
            foreach (listener; _listeners)
                listener(params);
        }

        else
        {
            ReturnType result;
            size_t i;
            result.length = size;

            foreach (listener; _listeners)
                result[i++] = listener(params);

            return result;
        }
    }

    /// Aliases $(DDOC_PSYMBOL call).
    ReturnType opCall(ParamTypes params)
    {
        static if (is(ReturnType == void))
            call(params);
        else
            return call(params);
    }

    /**
     * Removes the first listener.
     * Part of the bidirectional range interface.
     */
    @safe void popFront()
    {
        if (empty) return;
        _size -= 1;
        _listeners.removeFront;
    }

    /**
     * Removes the last listener.
     * Part of the bidirectional range interface.
     */
    @safe void popBack()
    {
        if (empty) return;
        _size -= 1;
        _listeners.removeBack;
    }

    /**
     * Copies the event to allow multiple range-like iteration.
     * Part of the bidirectional range interface.
     *
     * Returns:
     *  A copy of the event for independent iteration.
     */
    @safe auto save()
    {
        Event!ListenerType newEvent;
        newEvent._listeners = _listeners.dup;
        return newEvent;
    }

    /**
     * Prepends a listener to the listener collection.
     *
     * Params:
     *  listeners = The listeners to insert.
     */
    @safe void prepend(Type[] listeners...)
    {
        foreach (listener; listeners)
        {
            _size++;
            _listeners.insertFront(listener);
        }
    }

    /**
     * Appends a listener to the listener collection.
     *
     * Params:
     *  listeners = The listeners to insert.
     */
    @safe void append(Type[] listeners...)
    {
        foreach (listener; listeners)
        {
            _size++;
            _listeners.insertBack(listener);
        }
    }

    /**
     * Removed all occurrences of a listener.
     *
     * Params:
     *  listeners = The listeners to remove.
     */
    @safe void remove(Type[] listeners...)
    {
        import std.algorithm : find;

        foreach (listener; listeners)
        {
            auto matches = find!(f => f == listener)(_listeners[]);

            foreach (match; matches)
                _size -= 1;

            _listeners.remove(matches);
        }
    }

    /// Aliases $(DDOC_PSYMBOL append).
    @safe void opOpAssign(string s: "~")(Type listener)
    {
        append(listener);
    }

    /// Aliases $(DDOC_PSYMBOL remove).
    @safe void opOpAssign(string s: "-")(Type listener)
    {
        remove(listener);
    }
}

version (unittest)
{
    int add(int a, int b)
    {
        return a + b;
    }

    int multiply(int a, int b)
    {
        return a * b;
    }

    void doNothing() {}
}

/// Events return all their listener outputs in dynamic arrays.
unittest
{
    Event!(int function(int, int)) event;
    event.append(&add, &multiply);
    assert(event(5, 5) == [10, 25], "The event does not return an array of it's calling values.");
}

/// Adding and removing listeners is straightforward.
unittest
{
    Event!(int function(int, int)) event;
    event.append(&add, &multiply);
    assert(event.size == 2, "The event listener count does not increase upon addition.");
    event.remove(&add, &multiply);
    assert(event.size == 0, "The event listener count does not decrease upon removal.");
}

/// You can add the same listener multiple times. When removing it however, all matching listeners get removed.
unittest
{
    Event!(void function()) event;

    event ~= &doNothing;
    event.prepend(&doNothing);
    event.append(&doNothing);
    assert(event.size == 3, "The event listener does not add identical listeners.");
    event.remove(&doNothing);
    assert(event.listeners == [], "The event listener does not remove identical listeners.");
}

/// The event is a bidirectional range of it's listeners.
unittest
{
    import std.range : isBidirectionalRange, isInputRange;
    assert(isBidirectionalRange!VoidEvent, "The bidirectional range interface is not implemented.");

    Event!(void function()) event;
    event ~= &doNothing;
    auto checkpoint = event.save;

    foreach (listener; event) {}

    assert(event.empty, "The range is cleared after iteration.");
    assert(!checkpoint.empty, "The range checkpoint is not cleared after iteration.");
}

/// Range mutation primitives work.
unittest
{
    import std.exception : assertNotThrown;

    Event!(void function()) event;

    event ~= &doNothing;
    assert(event.front == &doNothing, "Returns the last remaining listener.");
    event.popFront();
    assert(event.back == null, "Does not return null when no listeners are present.");
    assertNotThrown(event.popBack(), "Popping an empty event throws.");
}

/// In case you want to remove all listeners.
unittest
{
    Event!(void function()) event;

    event ~= &doNothing;
    assert(!event.empty, "The event has no listeners, one listener expected.");
    event.clear();
    assert(event.empty, "The event is not empty.");
}
