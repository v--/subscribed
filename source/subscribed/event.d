/// An event structure representing a one-to-many function/delegate relationship.
module subscribed.event;

import std.traits : isCallable, ParameterTypeTuple, ReturnTypeTpl = ReturnType;
import std.experimental.allocator;

import subscribed.slist;

/**
 * An event structure representing a one-to-many function/delegate relationship.
 * It mimics a function by overriding the call operator.
 * It also implements the bidirectional range interface.
 *
 * Params:
 *  T = The listener type this event contains.
 */
struct Event(T) if (isCallable!T)
{
    /// The listeners' type.
    alias ListenerType = T;

    version (D_Ddoc)
    {
        /// The event's return type.
        alias ReturnType = void;
    }
    else
    {
        static if (is(ReturnTypeTpl!T == void))
            alias ReturnType = void;
        else
            alias ReturnType = ReturnTypeTpl!T[];
    }

    /// The event's argument type tuple.
    alias ParamTypes = ParameterTypeTuple!T;

    private
    {
        SList!T _listeners;
        int _size;
    }

    ~this()
    {
        _listeners.destroy();
    }

    /// The number of listeners.
    size_t size() const
    {
        return _size;
    }

    /// A range array of all the listeners.
    auto listeners()
    {
        return _listeners;
    }

    /**
     * A boolean property indicating whether there are listeners.
     * Part of the bidirectional range interface.
     */
    bool empty() const
    {
        return _listeners.empty;
    }

    /**
     * Get the first listener or throw an error if there are no listeners.
     * Part of the bidirectional range interface.
     */
    T front() const
    {
        return _listeners.front;
    }

    /**
     * Remove the first listener or throw an error if there are no listeners.
     * Part of the bidirectional range interface.
     */
    void popFront()
    {
        _listeners.popFront();
        _size -= 1;
    }

    /**
     * Prepend listeners to the listener collection.
     *
     * Params:
     *  listeners = The listeners to insert.
     */
    void prepend(T[] listeners...)
    {
        foreach (listener; listeners)
        {
            _size++;
            _listeners.insertFront(listener);
        }
    }

    /**
     * Get the last listener or throw an error if there are no listeners.
     * Part of the bidirectional range interface.
     */
    T back() const
    {
        return _listeners.back;
    }

    /**
     * Remove the last listener or throw an error if there are no listeners.
     * Part of the bidirectional range interface.
     */
    void popBack()
    {
        _listeners.popBack();
        _size -= 1;
    }

    /**
     * Appends a listener to the listener collection.
     *
     * Params:
     *  listeners = The listeners to insert.
     */
    void append(T[] listeners...)
    {
        foreach (listener; listeners)
        {
            _size++;
            _listeners.insertBack(listener);
        }
    }

    /**
     * Removed all occurrences of the given listeners.
     *
     * Params:
     *  listeners = The listeners to remove.
     */
    void remove(T[] listeners...)
    {
        foreach (listener; listeners)
            _size -= _listeners.removeAll(listener);
    }

    /**
     * Clears all listeners.
     */
    void clear()
    {
        _listeners.clear();
        _size = 0;
    }

    /**
     * Calls all the registered listeners in order.
     *
     * Params:
     *  params = The param tuple to call the listener with.
     */
    void call(ParamTypes params)
    {
        foreach (listener; _listeners)
            listener(params);
    }

    /// Aliases $(DDOC_PSYMBOL call).
    void opCall(ParamTypes params)
    {
        return call(params);
    }

    /**
     * Copies the event to allow multiple range-like iteration.
     * Part of the bidirectional range interface.
     */
    auto save()
    {
        return this;
    }

    ///
    auto opSlice()
    {
        return this;
    }

    /// Aliases $(DDOC_PSYMBOL append).
    void opOpAssign(string s: "~")(T listener)
    {
        append(listener);
    }

    /// Aliases $(DDOC_PSYMBOL remove).
    void opOpAssign(string s: "-")(T listener)
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
    import std.array : array;
    Event!(int function(int, int)) event;
    event.append(&add, &multiply);
    assert(event.front()(5, 5) == 10, "The event listeners are iterated in the same order they were added in");
    event.popFront();
    assert(event.front()(5, 5) == 25, "The event listeners are iterated in the same order they were added in");
}

/// Adding and removing listeners is straightforward.
unittest
{
    Event!(int function(int, int)) event;
    event.append(&add, &multiply);
    assert(event.size == 2, "The eveEvent!(void function())Event!(void function())nt listener count does not increase upon addition");
    event.remove(&add, &multiply);
    assert(event.size == 0, "The event listener count does not decrease upon removal");
}

/// You can add the same listener multiple times. When removing it however, all matching listeners get removed.
unittest
{
    Event!(void function()) event;

    event ~= &doNothing;
    event.prepend(&doNothing);
    event.append(&doNothing);
    assert(event.size == 3, "The event listener does not add identical listeners");
    event.remove(&doNothing);
    assert(event.empty, "The event listener does not remove identical listeners");
}

/// The event is a bidirectional range of it's listeners.
unittest
{
    import std.range : isBidirectionalRange;
    assert(isBidirectionalRange!(Event!(void function())), "The bidirectional range interface is not implemented");

    Event!(void function()) event;
    event ~= &doNothing;
    const checkpoint = event;

    foreach (listener; event) {}

    assert(!event.empty, "The range is cleared after foreach iteration");

    for (; !event.empty; event.popFront()) {}

    assert(event.empty, "The range is not cleared after manual iteration");
    assert(!checkpoint.empty, "The range checkpoint is cleared after iteration");
}

/// Range mutation primitives work.
unittest
{
    import std.exception : assertThrown;

    Event!(void function()) event;

    event ~= &doNothing;
    assert(event.front == &doNothing, "Returns the last remaining listener");
    event.popFront();
    assertThrown(event.back, "Getting the back of an empty event does not throw");
    assertThrown(event.popBack(), "Popping an empty event does not throw");
}

/// In case you want to remove all listeners.
unittest
{
    Event!(void function()) event;

    event ~= &doNothing;
    assert(!event.empty, "The event has no listeners, one listener expected");
    event.clear();
    assert(event.empty, "The event is not empty");
}
