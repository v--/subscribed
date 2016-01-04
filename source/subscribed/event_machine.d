/**
 * An event machine structure slightly resembling finite automata.
 * Authors: Ianis G. Vasilev `<mail@ivasilev.net>`
 * Copyright: Copyright © 2015-2016, Ianis G. Vasilev
 * License: BSL-1.0
 */
module subscribed.event_machine;

import std.string: format, indexOf;
import std.range: join;
import std.algorithm: all, map;

import subscribed.event;

/**
 * A state machine with simplified transitions - a wrapper around a state collection.
 * The machine has an initial state and a set of alternative states (loops are permited).
 * Any state can transition to any other state (the initial state is unreachable after transitioning away from it).
 * Transitioning between them is implemented by calling a state-specific event.
 *
 * Params:
 *  Type = The listener type this event contains. Default is `void function()`.
 *  States = An array of available state names. "Initial" is a reserved state and must not be used. By convention enum members are capitalized and so are state names.
 *
 * Bugs:
 *  Because DMD v2.069 and derivatives do not provide a good way to check identifier validity without using a custom parser, the user is responsible for providing state strings that are valid identifiers.
 */
struct EventMachine(string[] States, Type = void delegate())
    if (States.length > 0 && States.all!((string state) {
            return state != "Initial" && state.indexOf(' ') == -1 && state.indexOf(',') == -1 && state.indexOf('.') == -1;
        }) && isCallable!Type)
{
    /// The events' type.
    alias EventType = Event!Type;

    version (D_Ddoc)
        /// An enum generated from ["Initial"], concatenated with the $(DDOC_PSYMBOL States) array.
        enum State : size_t { Initial }
    else
        mixin("enum State : size_t { Initial, %s }".format(States.join(",")));

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
     * Can also be called using the alias subscribeTo#{StateName}.
     *
     * Params:
     *  state = The state whose event to subscribe to.
     *  listeners = The listeners to append.
     *
     * Returns:
     *  The new size of the event.
     *
     * See_Also:
     *  subscribed.event.Event.append
     */
    size_t subscribe(State state, EventType.ListenerType[] listeners...)
    {
        return _states[state].append(listeners);
    }

    /**
     * A function for appending a listener to the state event.
     * Can also be called using the alias goTo#{StateName}.
     *
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
     *  subscribed.event.Event.opCall
     */
    EventType.ReturnType go(State state, EventType.ParamTypes params)
    {
        scope (success) _state = state;

        static if (is(EventType.ReturnType == void))
            _states[state].opCall(params);
        else
            return _states[state].opCall(params);
    }

    version (D_Ddoc) {} else mixin(States.map!((string state) {
        return q{
            size_t subscribeTo%1$s(EventType.ListenerType[] listeners...)
            {
                return subscribe(State.%1$s, listeners);
            }

            EventType.ReturnType goTo%1$s(EventType.ParamTypes params)
            {
                %2$s go(State.%1$s, params);
            }
        }.format(state, is(EventType.ReturnType == void) ? "" : "return");
    }).join());
}

///
unittest
{
    // Since this example is generated from unit tests, delegates are required instead of functions

    int add(int a, int b)
    {
        return a + b;
    }

    EventMachine!(["StateA", "StateB"], int delegate(int, int)) machine;
    assert(machine.state == machine.State.Initial);
    machine.subscribe(machine.State.StateA, &add);
    assert(machine.goToStateA(1, 2) == [3]);
    assert(machine.state == machine.State.StateA);
    machine.go(machine.state, 2, 3); // Ensure loops are possible.
}

version (D_Ddoc)
{
    EventMachine!(["StateA", "StateB"]) machine;
}
