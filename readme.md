# subscribe.d

[![Build Status](https://api.travis-ci.org/v--/subscribed.svg?branch=master)](https://api.travis-ci.org/v--/subscribed.svg?branch=master) [![Coverage Status](https://coveralls.io/repos/github/v--/subscribed/badge.svg?branch=master)](https://coveralls.io/github/v--/subscribed?branch=master) [![DUB Package](https://img.shields.io/dub/v/subscribed.svg)](http://code.dlang.org/packages/subscribed)

---

A minimalistic library providing eventing-related structures.

All structures can be publicly imported with the `subscribed` package module or as separate modules.
A private module, `subscribed.support`, is used internally and is not part of the public API.

## Modules

### `subscribed.event`

An event structure representing a one-to-many function/delegate relationship. Events are basically collections of listeners (either functions or delegates) that have the same signature. Events are called like functions (via `opCall`) and return arrays, corresponding to the return values of individual listeners.

#### Use case

The module provides C#-like events for managing proper change propagation between different components of a program. Another cool usage is synchronizing thread outputs in a parallel pipeline.

### `subscribed.mediator`

A simple implementation of the mediator pattern. Basically an event collection with a unified interface and beforeEach/afterEach hooks. A more structured approach to the pub-sub module from the initial implementation of the library.

#### Use case

Imagine a world where numerous program components communicate across threads without ever knowing about each other's names and implementations.

### `subscribed.event_machine`

A structure representing a finite state automaton where by default any state (except for the initial one) can be reached from any other state at any time. Each state has an event that is triggered upon transitioning to it. State-dependent transitions should be implemented using beforeEach/afterEach hooks.

The main difference between the mediator and the event machine is that the former can have channels with different event signatures, but it also does not keep track of any state and simply routes events.

#### Use case

The module is intended for simplifying development of persistently running applications. Most components of a long-running program have multiple possible states and implementing switching between states without some publish-subscribe mechanism generally does not scale well.

## Example

```d
// Create and instantiate a simple finite-state machine structure.
alias SimpleMachine = EventMachine!(["running", "stopped"]);
SimpleMachine machine;

// Instantiate a mediator.
Mediator!([
    Channel.infer!("reset", void delegate()),
    Channel.infer!("increment", void delegate(int))
]) mediator;

int counter;

// Bind some events to the mediator.
mediator.on!"reset"(() {
    counter = 0;
});

mediator.on!"increment"((int amount) {
    counter += amount;
});

// Make sure nothing happens while the machine is not running.
// The listeners are only ran if the beforeEach hooks all return true.
mediator.beforeEach ~= (string channel) {
    return channel == "reset" || machine.state == SimpleMachine.State.running;
};

// Bind some events to the machine state changes.
machine.on!"stopped"(() {
    mediator.emit!"reset";
});

// Experiment with different operations.
machine.go!"running";
mediator.emit!"increment"(5);
mediator.emit!"increment"(3);
assert(counter == 8, "The counter has not incremented.");

machine.go!"stopped";
assert(counter == 0, "The counter was not reset by the machine.");

mediator.emit!"increment"(3);
assert(counter == 0, "The counter has incremented despite the machine being stopped.");
```

## Documentation

A ddox-generated documentation with example usage can be found [here](https://ivasilev.net/files/Docs/subscribed/index.html).
