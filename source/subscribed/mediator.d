/**
 * A simple mediator implementation.
 * Authors: Ianis G. Vasilev `<mail@ivasilev.net>`
 * Copyright: Copyright © 2015-2016, Ianis G. Vasilev
 * License: BSL-1.0
 */
module subscribed.mediator;

import std.experimental.allocator: theAllocator, make, dispose;
import std.functional: toDelegate;
import std.algorithm: all, map;
import std.string: format, indexOf;
import std.traits: isCallable;
import std.range: join;

import subscribed.event;

///
alias VoidMediator = Mediator!(void delegate());

/**
 * A hash table of events with beforeEach and afterEach hooks.
 *
 * Params:
 *  Type = The listener type this event contains. Default is `void delegate()`.
 *  KeyType = The hash table key type. Default is `string`.
 */
struct Mediator(Type, KeyType = string) if (isCallable!Type)
{

    /// The events' type.
    alias EventType = Event!Type;

    /// The hook to be executed before any transition. If false is returned, the no transition occurs.
    Event!(bool delegate()) beforeEach;

    /// The hook to be executed after a successful transition.
    Event!(void delegate()) afterEach;

    private
    {
        EventType*[KeyType] _channels;
    }

    ~this()
    {
        foreach (channel; _channels)
            theAllocator.dispose(channel);

        _channels.destroy();
    }

    /**
     * A function for appending listeners to the channel event.
     *
     * Params:
     *  channel = The channel whose event to subscribe to.
     *  listeners = The listeners to append.
     *
     * See_Also:
     *  subscribed.event.Event.append
     */
    void on(KeyType channel, EventType.ListenerType[] listeners...)
    {
        if (channel !in _channels)
            _channels[channel] = theAllocator.make!EventType;

        _channels[channel].append(listeners);
    }

    /**
     * A function for removing listeners from the channel event.
     *
     * Params:
     *  channel = The channel whose event to remove from.
     *  listeners = The listeners to remove.
     *
     * See_Also:
     *  subscribed.event.Event.append
     */
    void off(KeyType channel, EventType.ListenerType[] listeners...)
    {
        if (channel !in _channels)
            return;

        _channels[channel].remove(listeners);
    }

    /**
     * Calls all the registered listeners for the channel in order.
     *
     * Params:
     *  channel = The channel to emit a message to.
     *  params = the param tuple to call the listeners with.
     *
     * Returns:
     *  An array of results from the listeners.
     *  If $(DDOC_PSYMBOL EventType.ReturnType) is void, then this function also returns void.
     *
     * See_Also:
     *  subscribed.event.Event.call
     */
    EventType.ReturnType emit(KeyType channel, EventType.ParamTypes params)
    {
        foreach (condition; beforeEach())
            if (!condition)
                goto exit;

        if (channel !in _channels)
            goto exit;

        static if (is(EventType.ReturnType == void))
        {
            _channels[channel].call(params);
            afterEach();
        }
        else
        {
            auto result = _channels[channel].call(params);
            afterEach();
            return result;
        }

        exit:

        static if (is(EventType.ReturnType == void))
            return;
        else
            return EventType.ReturnType.init;
    }
}

/// The mediator can subscribe, unsubscribe and broadcast events.
unittest
{
    VoidMediator mediator;

    int counter;

    void increment()
    {
        counter++;
    }

    void decrement()
    {
        counter--;
    }

    mediator.on("inc", &increment);
    mediator.on("dec", &decrement);

    assert(counter == 0, "Mediator functions are called before any action is performed");
    mediator.emit("inc");
    assert(counter == 1, "The mediator does not call one of it's functions");
    mediator.emit("dec");
    assert(counter == 0, "The mediator does not call one of it's functions");

    mediator.beforeEach ~= () => false;

    assert(counter == 0, "The beforeEach hook does not work");
    mediator.emit("inc");
    assert(counter == 0, "The beforeEach hook does not work");
    mediator.emit("dec");
    assert(counter == 0, "The beforeEach hook does not work");

    mediator.beforeEach.clear();

    mediator.off("inc", &increment);
    mediator.off("dec", &decrement);

    assert(counter == 0, "The mediator called one of it's functions while unregistering them");
    mediator.emit("inc");
    assert(counter == 0, "The mediator did not remove a listener");
    mediator.emit("dec");
    assert(counter == 0, "The mediator did not remove a listener");
}
