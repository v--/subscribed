/**
 * An event structure representing a one-to-many function/delegate relationship.
 * Authors: Ianis G. Vasilev `<mail@ivasilev.net>`
 * Copyright: Copyright © 2015-2016, Ianis G. Vasilev
 * License: BSL-1.0
 */
module subscribed.event;

import std.container: DList;
import std.traits: isCallable, isDelegate, ReturnTypeTpl = ReturnType, ParameterTypeTuple;
import std.array: array;

///
alias VoidEvent = Event!(void delegate());

/**
 * An event structure representing a one-to-many function/delegate relationship.
 * It mimics a function by overriding the call operator.
 *
 * Params:
 *  Type = The listener type this event contains.
 *
 * Returns:
 *  An array of results of the calls of the correspoding listeners.
 */
struct Event(Type) if (isCallable!Type)
{
    /// The listeners' type.
    alias ListenerType = Type;

    static if (is(ReturnTypeTpl!Type == void))
        /// The event's return type.
        alias ReturnType = void;
    else
        alias ReturnType = ReturnTypeTpl!Type[];

    /// The event's argument type tuple.
    alias ParamTypes = ParameterTypeTuple!Type;

    private
    {
        DList!(Type) _listeners;
        int _size;
    }

    /// The number of listeners.
    @property size()
    {
        return _size;
    }

    /// An array of all the listeners.
    @property listeners()
    {
        return array(_listeners);
    }

    /// A boolean property indicating whether there are listeners.
    @property isEmpty()
    {
        return _listeners.empty;
    }

    ~this()
    {
        _listeners.destroy();
    }

    /**
     * Clears all listeners.
     */
    void clear()
    {
        _size = 0;
        _listeners.clear;
    }

    /**
     * Calls all the registered listeners in order.
     *
     * Params:
     *  params = the param tuple to call the listener with.
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

    /**
     * Aliases $(DDOC_PSYMBOL call).
     */
    ReturnType opCall(ParamTypes params)
    {
        static if (is(ReturnType == void))
            call(params);
        else
            return call(params);
    }

    /**
     * Removes the first listener.
     *
     * Returns:
     *  The removed listener.
     */
    Type shift()
    {
        if (_listeners.empty)
            return null;

        _size -= 1;
        _listeners.removeFront;
        return null;
    }

    /**
     * Removes the last listener.
     *
     * Returns:
     *  The removed listener.
     */
    Type pop()
    {
        //if (_listeners.empty)
            //return null;

        //_size -= 1;
        _listeners.removeBack;
        return null;
    }

    /**
     * Prepends a listener to the listener collection.
     *
     * Params:
     *  listeners = The listeners to append.
     *
     * Returns:
     *  The new size of the event.
     */
    void prepend(Type[] listeners...)
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
     *  listeners = The listeners to append.
     *
     * Returns:
     *  The new size of the event.
     */
    void append(Type[] listeners...)
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
    void remove(Type[] listeners...)
    {
        import std.algorithm: find;

        foreach (listener; listeners)
        {
            auto matches = find!(f => f == listener)(_listeners[]);

            foreach (match; matches)
                _size -= 1;

            _listeners.remove(matches);
        }
    }

    /**
     * Aliases $(DDOC_PSYMBOL append).
     */
    void opOpAssign(string s: "~")(Type listener)
    {
        append(listener);
    }

    /**
     * Aliases $(DDOC_PSYMBOL remove).
     */
    void opOpAssign(string s: "-")(Type listener)
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

///
unittest
{
    // The argument of the Event template is the listener signature.
    Event!(int function(int, int)) event;
    event.append(&add, &multiply);
    assert(event(5, 5) == [10, 25]);

    auto eventSize = event.size;
    event.remove(&add, &multiply);
    assert(event.size < eventSize);

    Event!(void function()) voidEvent;

    // You can add the same listener multiple times. When removing it however, all matching listeners get removed.
    voidEvent ~= &doNothing;
    voidEvent.prepend(&doNothing);
    voidEvent.append(&doNothing);
    assert(voidEvent.size == 3); // The total number of listeners is returned on prepend/append.

    voidEvent();
    eventSize = voidEvent.size;
    voidEvent.remove(&doNothing);
    assert(voidEvent.size < eventSize);
    voidEvent -= &doNothing;
    assert(voidEvent.size == 0); // No listeners left.
    assert(voidEvent.listeners == []);

    voidEvent ~= &doNothing;

    // You can off course shift and pop listeners.
    //assert(voidEvent.shift() == &doNothing); // Returns doNothing.
    assert(voidEvent.pop() == null); // Returns null, because no listeners are available.

    voidEvent ~= &doNothing;

    // In case you want to remove all listeners:
    assert(!voidEvent.isEmpty); // The event has one listener.
    voidEvent.clear();
}
