/**
 * An event structure representing a one-to-many function/delegate relationship.
 * Authors: Ianis G. Vasilev `<mail@ivasilev.net>`, a.k.a. ivasilev / ianis / v--
 * Copyright: Copyright © 2015, Ianis G. Vasilev
 * License: BSL-1.0
 */
module subscribed.event;

import std.container: DList;
import std.algorithm: find;
import std.traits: isCallable, isDelegate, ReturnType, ParameterTypeTuple;
import std.array: array;

/**
 * An event structure representing a one-to-many function/delegate relationship.
 * It mimics a function by overriding the call operator.
 *
 * Params:
 *  Type = the listener type this event contains.
 *
 * Returns:
 *  An array of results of the calls of the correspoding listeners.
 */
struct Event(Type = void function()) if (isCallable!Type)
{
    private
    {
        DList!(Type) _listeners;
        int _size;
    }

    /// The listeners' type.
    alias ListenerType = Type;

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

    /**
     * Clears all listeners.
     *
     * Returns:
     *  The number of listeners removed.
     */
    size_t clear()
    {
        auto oldSize = _size;
        _size = 0;
        _listeners.clear;
        return oldSize;
    }

    /**
     * Calls all the registered listeners in order.
     *
     * Params:
     *  args = the arguments tuple to call the listener with.
     *
     * Returns:
     *  An array of results from the listeners.
     *  If $(DDOC_PSYMBOL ReturnType) is void, then this function also returns void.
     */
    auto opCall(ParameterTypeTuple!Type args)
    {
        static if (is(ReturnType!Type == void))
        {
            foreach (del; _listeners)
                del(args);
        }

        else
        {
            ReturnType!Type[] result;

            foreach (del; _listeners)
                result ~= del(args);

            return result;
        }
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
        auto front = _listeners.front;
        _listeners.removeFront;
        return front;
    }

    /**
     * Removes the last listener.
     *
     * Returns:
     *  The removed listener.
     */
    Type pop()
    {
        if (_listeners.empty)
            return null;

        _size -= 1;
        auto back = _listeners.back;
        _listeners.removeBack;
        return back;
    }

    /**
     * Prepends a listener to the listener collection.
     *
     * Params:
     *  listener = The listener to append.
     *
     * Returns:
     *  The new size of the event.
     */
    size_t prepend(Type listener)
    {
        _size++;
        _listeners.insertFront(listener);
        return _size;
    }

    /**
     * Appends a listener to the listener collection.
     *
     * Params:
     *  listener = The listener to append.
     *
     * Returns:
     *  The new size of the event.
     */
    size_t append(Type listener)
    {
        _size++;
        _listeners.insertBack(listener);
        return _size;
    }

    /**
     * Removed all occurrences of a listener.
     *
     * Params:
     *  listener = The listener to remove.
     *
     * Returns:
     *  The number of removed listeners.
     */
    size_t remove(Type listener)
    {
        auto matches = find!(f => f == listener)(_listeners[]);
        auto length = array(matches).length;
        _size -= length;
        _listeners.remove(matches);
        return length;
    }

    /**
     * Aliases $(DDOC_PSYMBOL append).
     */
    size_t opOpAssign(string s: "~")(Type listener)
    {
        return append(listener);
    }

    /**
     * Aliases $(DDOC_PSYMBOL remove).
     */
    size_t opOpAssign(string s: "-")(Type listener)
    {
        return remove(listener);
    }
}

///
unittest
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

    // The argument of the Event template is the listener signature.
    Event!(int delegate(int, int)) event;
    event ~= &add;
    event ~= &multiply;
    assert(event(5, 5) == [10, 25]);

    // For convenience, Event's default type parameter is a signature for void functions without parameters.
    version (unittest)
        Event!(void delegate()) voidEvent;
    else
        Event voidEvent;

    // You can add the same listener multiple times. When removing it however, all matching listeners get removed.
    voidEvent ~= &doNothing;
    voidEvent.prepend(&doNothing);
    assert(voidEvent.append(&doNothing) == 3); // The total number of listeners is returned on prepend/append.

    voidEvent();

    assert(voidEvent.remove(&doNothing) == 3); // Returns the number of returned listeners.
    voidEvent -= &doNothing; // Returns false, meaning that there were no removed listeners.
    assert(voidEvent.size == 0); // No listeners left.
    assert(voidEvent.listeners == []);

    voidEvent ~= &doNothing;

    // You can off course shift and pop listeners.
    assert(voidEvent.shift() == &doNothing); // Returns doNothing.
    assert(voidEvent.pop() == null); // Returns null, because no listeners are available.

    voidEvent ~= &doNothing;

    // In case you want to remove all listeners:
    assert(!voidEvent.isEmpty); // The event has one listener.
    assert(voidEvent.clear() == 1); // Returns the number removed listeners.
}
