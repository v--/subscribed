/**
 * An event machine structure slightly resembling finite automata.
 * Authors: Ianis G. Vasilev `<mail@ivasilev.net>`
 * Copyright: Copyright © 2015-2016, Ianis G. Vasilev
 * License: BSL-1.0
 */
module subscribed.event_machine;

import std.functional: toDelegate;
import std.algorithm: all, map;
import std.string: format, indexOfAny;
import std.traits: isCallable;
import std.range: join;

import subscribed.event;

/**
 * A state machine with simplified transitions - a wrapper around a state collection.
 * State-dependent transitions should be implemented using beforeEach/afterEach hooks.
 * A transition can be canceled by returning false from the any beforeEach listener.
 * The machine has an initial state and a set of alternative states (loops are permitted).
 * Any state can transition to any other state (the initial state is unreachable after transitioning away from it).
 *
 * Params:
 *  States = An array of available state names. "Initial" is a reserved state and must not be used. By convention enum members are capitalized and so are state names.
 *  Type = The listener type this event contains. Default is `void delegate()`.
 *
 * Bugs:
 *  Because DMD v2.069 and derivatives do not provide a good way to check identifier validity without using a custom parser, the user is responsible for providing state strings that are valid identifiers.
 */
struct EventMachine(string[] States, Type = void delegate())
    if (isCallable!Type && States.length > 0 && States.all!((string state) {
        return state != "Initial" && state.indexOfAny([' ', ',', '.']);
    }))
{
    version (D_Ddoc)
        /// An enum generated from ["Initial"], concatenated with the $(DDOC_PSYMBOL States) array.
        enum State: size_t { Initial }
    else
        mixin("enum State: size_t { Initial, %s }".format(States.join(",")));

    /// The events' type.
    alias EventType = Event!Type;

    /// The hook to be executed before any transition. If false is returned, the no transition occurs.
    Event!(bool delegate(State, State)) beforeEach;

    /// The hook to be executed after a successful transition.
    Event!(void delegate(State, State)) afterEach;

    private
    {
        State _state = State.Initial;
        mixin("EventType[%d] _states;".format(States.length + 1));
    }

    /// The active state.
    @property state()
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
    void on(State state, EventType.ListenerType[] listeners...)
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
    void off(State state, EventType.ListenerType[] listeners...)
    {
        _states[state].remove(listeners);
    }

    /**
     * Calls all the registered listeners in order.
     *
     * Params:
     *  state = The state to transition to.
     *  params = the param tuple to call the listener with.
     *
     * Returns:
     *  An array of results from the listeners.
     *  If $(DDOC_PSYMBOL EventType.ReturnType) is void, then this function also returns void.
     *
     * See_Also:
     *  subscribed.event.Event.call
     */
    EventType.ReturnType go(State state, EventType.ParamTypes params)
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
                _states[state].append(listeners);
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

///
unittest
{
    EventMachine!(["StateA", "StateB", "StateC"], int delegate(int, int)) machine;
    assert(machine.state == machine.State.Initial);
    machine.on(machine.State.StateA, toDelegate(&add));
    assert(machine.goToStateA(1, 2) == [3]);
    assert(machine.state == machine.State.StateA);
    machine.go(machine.state, 2, 3); // Ensure loops are possible.

    bool flag;

    machine.beforeEach ~= (oldState, newState) {
        assert(oldState == machine.State.StateA && !flag);
        return newState != machine.State.StateC;
    };

    machine.afterEach ~= (oldState, newState) {
        assert(oldState == machine.State.StateA);
    };

    machine.goToStateC(5, 5);
    assert(machine.state == machine.State.StateA);
    assert(!flag);
    machine.goToStateB(5, 5);
}

version (D_Ddoc)
{
    EventMachine!(["StateA", "StateB"]) machine;
}
