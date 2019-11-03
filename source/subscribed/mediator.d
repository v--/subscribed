// A simple mediator implementation.
module subscribed.mediator;

import std.traits : isCallable;
import std.array : replace;
import std.meta;

import subscribed.event;

/**
 * A simple mediator implementation.
 * More precisely, an event collection with a unified interface and beforeEach/afterEach hooks.
 *
 * Params:
 *  params - A list alternating between index types and callable types.
 */
struct Mediator(params...)
{
    static assert(params.length % 2 == 0, "The parameter count must be even");

    /// The type of the (indexing) channel names.
    alias IType = typeof(params[0]);

    private
    {
        struct Channel(IType name_, T) if (isCallable!T)
        {
            alias Type = T;
            enum name = name_;
        }

        template channels(params...)
        {
            static if (params.length == 0)
            {
                alias channels = AliasSeq!();
            }
            else
            {
                static assert(
                    is(typeof(params[0]) == IType) && isCallable!(params[1]),
                    "Parameters must alternate between index types and callable types"
                );

                alias channels = AliasSeq!(Channel!(params[0], params[1]), channels!(params[2..$]));
            }
        }

        mixin template bindChannel(c)
        {
            private
            {
                alias EventType = Event!(c.Type);
                EventType event;
            }

            void on(IType channel : c.name)(EventType.ListenerType[] listeners...)
            {
                event.append(listeners);
            }

            void off(IType channel : c.name)(EventType.ListenerType[] listeners...)
            {
                event.remove(listeners);
            }

            void emit(IType channel : c.name)(EventType.ParamTypes params)
            {
                foreach (listener; beforeEach.listeners)
                    if (!listener(channel))
                        return;

                event.call(params);
                afterEach(channel);
            }
        }
    }

    /// The hook to be executed before any transition. If false is returned, the no transition occurs.
    Event!(bool delegate(IType)) beforeEach;

    /// The hook to be executed after a successful transition.
    Event!(void delegate(IType)) afterEach;

    version (D_Ddoc)
    {
        alias EventType = Event!(void function());

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
        void on(IType channel)(EventType.ListenerType[] listeners...);

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
        void off(IType channel)(EventType.ListenerType[] listeners...);

        /**
         * Calls all the registered listeners for the channel in order.
         *
         * Params:
         *  channel = The channel to emit a message to.
         *  params = The param tuple to call the listeners with.
         *
         * Returns:
         *  An array of results from the listeners.
         *  If $(DDOC_PSYMBOL EventType.ReturnType) is void, then this function also returns void.
         *
         * See_Also:
         *  subscribed.event.Event.call
         */
        void emit(string channel)(EventType.ParamTypes params);
    }

    static foreach (channel; channels!params)
        mixin bindChannel!channel;
}

/// The mediator events can be strings.
unittest
{
    Mediator!(
        "start", void delegate(),
        "stop", void delegate()
    ) mediator;

    mediator.emit!"start"();
}

/// The mediator events can be enum members.
unittest
{
    enum Event { start, stop }

    Mediator!(
        Event.start, void delegate(),
        Event.stop, void delegate()
    ) mediator;

    mediator.emit!(Event.start)();
}

/// The mediator events cannot be of mixed type.
unittest
{
    immutable canCompile = __traits(compiles, Mediator!(
        "start", void delegate(),
        3, void delegate()
    ));

    assert(!canCompile, "Can compile mediators with mixed index types");
}

/// The mediator can subscribe, unsubscribe and broadcast events.
unittest
{
    Mediator!(
        "inc", void delegate(),
        "dec", void delegate(),
        "reset counter", void delegate()
    ) mediator;

    int counter;

    void increment()
    {
        counter++;
    }

    void decrement()
    {
        counter--;
    }

    void reset()
    {
        counter = 0;
    }

    mediator.on!"inc"(&increment);
    mediator.on!"dec"(&decrement);
    mediator.on!"reset counter"(&reset);

    assert(counter == 0, "Mediator functions are called before any action is performed");
    mediator.emit!"inc"();
    assert(counter == 1, "The mediator does not call one of it's functions");
    mediator.emit!"dec"();
    assert(counter == 0, "The mediator does not call one of it's functions");

    assert(counter == 0, "Mediator functions are called before any action is performed");
    mediator.emit!"inc"();
    assert(counter == 1, "The mediator does not call one of it's functions");
    mediator.emit!"reset counter"();
    assert(counter == 0, "The mediator does not call one of it's functions");

    mediator.beforeEach ~= string => false;

    assert(counter == 0, "The beforeEach hook does not work");
    mediator.emit!"inc"();
    assert(counter == 0, "The beforeEach hook does not work");
    mediator.emit!"dec"();
    assert(counter == 0, "The beforeEach hook does not work");

    mediator.beforeEach.clear();

    mediator.off!"inc"(&increment);
    mediator.off!"dec"(&decrement);

    assert(counter == 0, "The mediator called one of it's functions while unregistering them");
    mediator.emit!"inc"();
    assert(counter == 0, "The mediator did not remove a listener");
    mediator.emit!"dec"();
    assert(counter == 0, "The mediator did not remove a listener");
}
