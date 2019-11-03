/// An event machine structure slightly resembling finite automata.
module subscribed.event_machine;

import std.traits : isCallable, EnumMembers;

import subscribed.event;

/**
 * A state machine with simplified transitions - a wrapper around a state collection.
 * State-dependent transitions should be implemented using beforeEach/afterEach hooks.
 * A transition can be canceled by returning false from the any beforeEach listeners.
 * The machine has an initial state and a set of alternative states (loops are permitted).
 * Any state can transition to any other state (the initial state is unreachable after transitioning away from it).
 *
 * Params:
 *  State_ = An enum of available states.
 *  T = The listener type this event contains. Default is `void delegate()`.
 */
struct EventMachine(State_, T = void delegate())
    if (is(typeof(State_.init)) &&
        State_.min != State_.max &&
        isCallable!T)
{
    /// An alias to the $(DDOC_PSYMBOL State_) parameter.
    alias State = State_;

    /// The events' type.
    alias EventType = Event!T;

    /// The hook to be executed before any transition. If false is returned, no transition occurs.
    Event!(bool delegate(State, State)) beforeEach;

    /// The hook to be executed after a successful transition.
    Event!(void delegate(State, State)) afterEach;

    private State _state = State.init;

    /// The active state.
    State state() const
    {
        return _state;
    }

    version (D_Ddoc)
    {
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
        void on(State state)(EventType.ListenerType[] listeners...);

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
        void off(State state)(EventType.ListenerType[] listeners...);

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
        void go(State state)(EventType.ParamTypes params);
    }

    private mixin template bindStateTransitions(State s)
    {
        private EventType event;

        void on(State state : s)(EventType.ListenerType[] listeners...)
        {
            event.append(listeners);
        }

        void off(State state : s)(EventType.ListenerType[] listeners...)
        {
            event.remove(listeners);
        }

        void go(State state : s)(EventType.ParamTypes params)
        {
            auto oldState = _state;

            foreach (listener; beforeEach.listeners)
                if (!listener(oldState, state))
                    return;

            event.call(params);
            _state = state;
            afterEach(oldState, state);
        }
    }

    static foreach (State s; EnumMembers!State)
        mixin bindStateTransitions!s;
}

/// An event machine stores it's state.
unittest
{
    enum State { stateA, stateB }
    alias Machine = EventMachine!State;
    Machine machine;

    assert(machine.state == State.stateA, "The machine is not initially in it's default state");
    machine.go!(State.stateB)();
    assert(machine.state == State.stateB, "The machine does not navigate to other states");
    machine.go!(State.stateB)();
    assert(machine.state == State.stateB, "The machine does not permit loops");
    machine.go!(State.stateA)();
    assert(machine.state == State.stateA, "The machine does not navigate to other states");
}

/// An event machine supports enums with negative values.
unittest
{
    enum State { stateA = -21, stateB = 3 }
    alias Machine = EventMachine!State;
    Machine machine;

    assert(machine.state == State.stateA, "The machine is not initially in it's default state");
    machine.go!(State.stateB)();
    assert(machine.state == State.stateB, "The machine does not navigate to other states");
}

/// beforeEach and afterEach run appropriately.
unittest
{
    enum State { stateA, stateB }
    alias Machine = EventMachine!(State, void delegate());
    Machine machine;

    bool beforeEachRan, afterEachRan;

    machine.beforeEach ~= (oldState, newState) {
        assert(oldState == State.stateA, "The machine doesn't move from it's initial state");
        assert(newState == State.stateB, "The machine doesn't move to a non-initial state");
        beforeEachRan = true;
        return true;
    };

    machine.afterEach ~= (oldState, newState) {
        afterEachRan = true;
        assert(oldState == State.stateA, "The machine doesn't move from it's initial state");
        assert(newState == State.stateB, "The machine doesn't move to a non-initial state");
    };

    machine.go!(State.stateB)();
    assert(beforeEachRan, "The beforeEach hook has been ran");
    assert(afterEachRan, "The afterEach hook has been ran");
}

/// beforeEach can cancel subsequent events.
unittest
{
    enum State { stateA, stateB }
    alias Machine = EventMachine!(State, void delegate());
    Machine machine;

    machine.beforeEach ~= (oldState, newState) {
        return false;
    };

    machine.on!(State.stateA)(() {
        assert(false, "The machine moves to stateA despite the failing beforeEach check");
    });

    machine.go!(State.stateA)();
}
