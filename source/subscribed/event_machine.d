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
 * The machine has an initial state and a set of alternative states.
 * Transitioning between them is implemented by calling a state-specific event.
 *
 * On template instantiation additional members are generated:
 *
 * * enum State : size_t: An enum generated from $(DDOC_PSYMBOL States) with an additional "Initial" state.
 *
 * * size_t subscribe(State state)(EventType.ListenerType listener): A function for appending a listener to the state event.
 *   Can also be called using the alias subscribeTo#{StateName}
 *
 * * EventType.ReturnType go(State state)(EventType.ParamTypes params): A function for changing the current state.
 *   Can also be called using the alias goTo#{StateName}
 *
 * Params:
 *  States = An array of available state names. "Initial" is a reserved state and must not be used. By convention enum members are capitalized and so are state names.
 *  Type = The listener type this event contains. Default is `void function()`.
 *
 * Bugs:
 *  Because DMD v2.069 and derivatives do not provide a good way to check identifier validity without using a custom parser, the user is responsible for providing state strings that are valid identifiers.
 */
struct EventMachine(string[] States, Type = void function())
    if (States.length > 0 && States.all!((string state) {
            return state != "Initial" && state.indexOf(' ') == -1 && state.indexOf(',') == -1;
        }) && isCallable!Type)
{
    /// The events' type.
    alias EventType = Event!Type;

    /// The state enum.
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

    mixin(States.map!((string state) {
        return q{
            /// asdf
            size_t subscribe(State state: State.%1$s)(EventType.ListenerType listener)
            {
                return _states[State.%1$s].append(listener);
            }

            alias subscribeTo%1$s = subscribe!(State.%1$s);

            EventType.ReturnType go(State state: State.%1$s)(EventType.ParamTypes params)
            {
                scope(success) _state = State.%1$s;
                %2$s _states[State.%1$s](params);
            }

            alias goTo%1$s = go!(State.%1$s);
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
    machine.subscribe!(machine.State.StateA)(&add);
    assert(machine.goToStateA(1, 2) == [3]);
}
