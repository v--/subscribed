/**
 * An event machine structure slightly resembling finite automata.
 * Authors: Ianis G. Vasilev `<mail@ivasilev.net>`
 * Copyright: Copyright © 2015-2016, Ianis G. Vasilev
 * License: BSL-1.0
 */
module subscribed.event_machine;

import std.algorithm: all;
import std.traits: isCallable;

import subscribed.support;
import subscribed.event;

/**
 * A state machine with simplified transitions - a wrapper around a state collection.
 * State-dependent transitions should be implemented using beforeEach/afterEach hooks.
 * A transition can be canceled by returning false from the any beforeEach listeners.
 * The machine has an initial state and a set of alternative states (loops are permitted).
 * Any state can transition to any other state (the initial state is unreachable after transitioning away from it).
 *
 * Params:
 *  States = An array of available state names. "Initial" is a reserved state and must not be used. By convention enum members are capitalized and so are state names.
 *  Type = The listener type this event contains. Default is `void delegate()`.
 */
struct EventMachine(string[] States, Type = void delegate())
    if (isCallable!Type && States.length > 0 && States.all!((string state) {
        return isValidIdentifier(state) && state != "Initial";
    }))
{
    import std.algorithm: map;
    import std.string: format;
    import std.range: join;

    version (D_Ddoc)
        /// An enum generated from ["Initial"], concatenated with the $(DDOC_PSYMBOL States) array.
        enum State: size_t { Initial }
    else
        mixin("enum State: size_t { Initial, %s }".format(States.join(",")));

    /// The events' type.
    alias EventType = Event!Type;

    /// The hook to be executed before any transition. If false is returned, no transition occurs.
    Event!(bool delegate(State, State)) beforeEach;

    /// The hook to be executed after a successful transition.
    Event!(void delegate(State, State)) afterEach;

    private
    {
        State _state = State.Initial;
        mixin("EventType[%d] _states;".format(States.length + 1));
    }

    /// The active state.
    @safe @nogc @property state() const
    {
        return _state;
    }

    /**
     * A function for appending listeners to the state event.
     * Can also be called using the alias on#{StateName}.
     *
     * Params:
     *  state = The state whose event to subscribe to.
     *  listeners = The listeners to append.
     *
     * See_Also:
     *  subscribed.event.Event.append
     */
    @safe void on(const State state, EventType.ListenerType[] listeners...)
    {
        _states[state].append(listeners);
    }

    /**
     * A function for removing listeners from the state event.
     *
     * Params:
     *  state = The state whose event to remove from.
     *  listeners = The listeners to remove.
     *
     * See_Also:
     *  subscribed.event.Event.append
     */
    @safe void off(const State state, EventType.ListenerType[] listeners...)
    {
        _states[state].remove(listeners);
    }

    /**
     * Calls all the registered listeners in order.
     * Can also be called using the alias goTo#{StateName}.
     *
     * Params:
     *  state = The state to transition to.
     *  params = The param tuple to call the listener with.
     *
     * Returns:
     *  An array of results from the listeners.
     *  If $(DDOC_PSYMBOL EventType.ReturnType) is void, then this function also returns void.
     *
     * See_Also:
     *  subscribed.event.Event.call
     */
    EventType.ReturnType go(const State state, EventType.ParamTypes params)
    {
        foreach (condition; beforeEach(_state, state))
        {
            if (!condition)
            {
                static if (is(EventType.ReturnType == void))
                    return;
                else
                    return EventType.ReturnType.init;
            }
        }

        auto oldState = _state;

        static if (is(EventType.ReturnType == void))
        {
            _states[state].call(params);
            _state = state;
            afterEach(oldState, state);
        }
        else
        {
            auto result = _states[state].call(params);
            _state = state;
            afterEach(oldState, state);
            return result;
        }
    }

    version (D_Ddoc) {} else mixin(States.map!((string state) {
        return q{
            void on%1$s(EventType.ListenerType[] listeners...)
            {
                on(State.%1$s, listeners);
            }

            EventType.ReturnType goTo%1$s(EventType.ParamTypes params)
            {
                %2$s go(State.%1$s, params);
            }
        }.format(state, is(EventType.ReturnType == void) ? "" : "return");
    }).join());
}

version (unittest)
{
    int add(int a, int b)
    {
        return a + b;
    }
}

/// An event machine stores it's state.
unittest
{
    alias Machine = EventMachine!(["StateA", "StateB"]);
    Machine machine;

    assert(machine.state == Machine.State.Initial, "The machine is not initially in it's default state.");
    machine.goToStateA();
    assert(machine.state == Machine.State.StateA, "The machine does not navigate to other states.");
    machine.goToStateA();
    assert(machine.state == Machine.State.StateA, "The machine does not permit loops.");
    machine.goToStateB();
    assert(machine.state == Machine.State.StateB, "The machine does not navigate to other states after exiting the initial one.");
}

/// Switching states calls the corresponding events.
unittest
{
    import std.functional: toDelegate;

    EventMachine!(["StateA"], int delegate(int, int)) machine;
    machine.onStateA(toDelegate(&add));
    assert(machine.goToStateA(1, 2) == [3], "The underlying event does not function properly.");
}

/// beforeEach and afterEach run appropriately.
unittest
{
    alias Machine = EventMachine!(["StateA"], void delegate());
    Machine machine;

    bool beforeEachRan, afterEachRan;

    machine.beforeEach ~= (oldState, newState) {
        assert(oldState == Machine.State.Initial, "The machine moves from it's initial state.");
        assert(newState == Machine.State.StateA, "The machine moves to a non-initial state.");
        beforeEachRan = true;
        return true;
    };

    machine.afterEach ~= (oldState, newState) {
        afterEachRan = true;
        assert(oldState == Machine.State.Initial, "The machine moves from it's initial state.");
        assert(newState == Machine.State.StateA, "The machine moves to a non-initial state.");
    };

    machine.goToStateA();
    assert(beforeEachRan, "The beforeEach hook has been ran.");
    assert(afterEachRan, "The afterEach hook has been ran.");
}

/// beforeEach can cancel subsequent events.
unittest
{
    EventMachine!(["StateA"], void delegate()) machine;

    machine.beforeEach ~= (oldState, newState) {
        return false;
    };

    machine.onStateA(() {
        assert(false, "The machine moves to StateA despite the failing beforeEach check.");
    });

    machine.goToStateA();
}
