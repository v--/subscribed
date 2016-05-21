/// An event machine structure slightly resembling finite automata.
module subscribed.event_machine;

import std.algorithm: all;
import std.traits: isCallable;

import subscribed.support;
import subscribed.event;

/**
 * A state machine with simplified transitionS - a wrapper around a state collection.
 * State-dependent transitionS should be implemented using beforeEach/afterEach hooks.
 * A transition can be canceled by returning false from the any beforeEach listeners.
 * The machine has an initial state and a set of alternative states (loops are permitted).
 * Any state can transition to any other state (the initial state is unreachable after transitioning away from it).
 *
 * Params:
 *  states = An array of available state names. "initial" is a reserved state and must not be used. State names should be camelCased, just like enum members.
 *  Type = The listener type this event contains. Default is `void delegate()`.
 */
struct EventMachine(string[] states, Type = void delegate())
    if (isCallable!Type && states.length > 0 && states.all!((string state) {
        return isValidIdentifier(state) && state != "initial";
    }))
{
    import std.algorithm: map;
    import std.string: format;
    import std.range: join;

    version (D_Ddoc)
        /// An enum generated from ["initial"], concatenated with the $(DDOC_PSYMBOL states) array.
        enum State: size_t { initial }
    else
        mixin("enum State: size_t { initial, %s }".format(states.join(",")));

    /// The events' type.
    alias EventType = Event!Type;

    /// The hook to be executed before any transition. If false is returned, no transition occurs.
    Event!(bool delegate(State, State)) beforeEach;

    /// The hook to be executed after a successful transition.
    Event!(void delegate(State, State)) afterEach;

    private
    {
        State _state = State.initial;
        mixin("EventType[%d] _states;".format(states.length + 1));
    }

    /// The active state.
    @safe @nogc @property state() const
    {
        return _state;
    }

    /**
     * A function for appending listeners to the state event.
     * Can also be called using the alias on!#{stateName}, where the state name is a string.
     *
     * Params:
     *  state = The state whose event to subscribe to.
     *  listeners = The listeners to append.
     *
     * See_Also:
     *  subscribed.event.Event.append
     */
    @safe void on(State state)(EventType.ListenerType[] listeners...) if (state != State.initial)
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
    @safe void off(State state)(EventType.ListenerType[] listeners...) if (state != State.initial)
    {
        _states[state].remove(listeners);
    }

    /**
     * Calls all the registered listeners in order.
     * Can also be called using the alias go!#{stateName}, where the state name is a string.
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
    EventType.ReturnType go(State state)(EventType.ParamTypes params) if (state != State.initial)
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

    version (D_Ddoc) {} else mixin(states.map!((string state) {
        return q{
            void on(string state: "%1$s")(EventType.ListenerType[] listeners...)
            {
                on!(State.%1$s)(listeners);
            }

            EventType.ReturnType go(string state: "%1$s")(EventType.ParamTypes params)
            {
                %2$s go!(State.%1$s)(params);
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

/// An event machine cannot go to it's initial state
unittest
{
    alias Machine = EventMachine!(["state"]);
    Machine machine;

    assert(!__traits(compiles, machine.go!(Machine.State.initial)), "The machine can return to it's initial state state.");
}

/// An event machine stores it's state.
unittest
{
    alias Machine = EventMachine!(["stateA", "stateB"]);
    Machine machine;

    assert(machine.state == Machine.State.initial, "The machine is not initially in it's default state.");
    machine.go!"stateA";
    assert(machine.state == Machine.State.stateA, "The machine does not navigate to other states.");
    machine.go!"stateA";
    assert(machine.state == Machine.State.stateA, "The machine does not permit loops.");
    machine.go!"stateB";
    assert(machine.state == Machine.State.stateB, "The machine does not navigate to other states after exiting the initial one.");
}

/// Switching states calls the corresponding events.
unittest
{
    import std.functional: toDelegate;

    EventMachine!(["stateA"], int delegate(int, int)) machine;
    machine.on!"stateA"(toDelegate(&add));
    assert(machine.go!"stateA"(1, 2) == [3], "The underlying event does not function properly.");
}

/// beforeEach and afterEach run appropriately.
unittest
{
    alias Machine = EventMachine!(["stateA"], void delegate());
    Machine machine;

    bool beforeEachRan, afterEachRan;

    machine.beforeEach ~= (oldState, newState) {
        assert(oldState == Machine.State.initial, "The machine moves from it's initial state.");
        assert(newState == Machine.State.stateA, "The machine moves to a non-initial state.");
        beforeEachRan = true;
        return true;
    };

    machine.afterEach ~= (oldState, newState) {
        afterEachRan = true;
        assert(oldState == Machine.State.initial, "The machine moves from it's initial state.");
        assert(newState == Machine.State.stateA, "The machine moves to a non-initial state.");
    };

    machine.go!"stateA";
    assert(beforeEachRan, "The beforeEach hook has been ran.");
    assert(afterEachRan, "The afterEach hook has been ran.");
}

/// beforeEach can cancel subsequent events.
unittest
{
    EventMachine!(["stateA"], void delegate()) machine;

    machine.beforeEach ~= (oldState, newState) {
        return false;
    };

    machine.on!"stateA"(() {
        assert(false, "The machine moves to stateA despite the failing beforeEach check.");
    });

    machine.go!"stateA";
}
