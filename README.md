# subscribe.d

[![Tests](https://github.com/v--/subscribed/workflows/Tests/badge.svg)](https://github.com/v--/subscribed/actions?query=workflow%3ATests) [![DUB Package](https://img.shields.io/dub/v/subscribed.svg)](http://code.dlang.org/packages/subscribed)

A minimalistic library providing eventing-related structures.

All structures can be publicly imported with the `subscribed` package module or as separate modules.
A "private" module, `subscribed.slist`, is used internally and is not part of the public API.

Below is a brief introduction. Automatically generated documentation can be found in http://v--.github.io/subscribed/.

## Modules

### `subscribed.event`

An event structure representing a one-to-many function/delegate relationship. Events are basically collections of listeners (either functions or delegates) that have the same signature. Events are called like functions (via `opCall`) with a void return type. The values of the individual listeners can be queries by iterating the listeners. See the documentation for usage details.

### `subscribed.mediator`

A simple implementation of the mediator pattern. Basically an event collection with a unified interface and beforeEach/afterEach hooks. A more structured approach to the pub-sub module from the initial implementation of the library.

### `subscribed.event_machine`

A structure representing a finite state automaton where by default any state can be reached from any other state at any time. Each state has an event that is triggered upon transitioning to it. State-dependent transitions should be implemented using beforeEach/afterEach hooks.

The main difference between the mediator and the event machine is that the former can have channels with different event signatures, but it also does not keep track of any state and simply routes events.

## Example

```d
// Create and instantiate a simple finite-state machine structure.
enum SimpleState { running, stopped }
alias SimpleMachine = EventMachine!SimpleState;
SimpleMachine machine;

// Create and instantiate a simple mediator.
enum SimpleEvent { reset, increment }
alias SimpleMediator = Mediator!(
    SimpleEvent.reset, void delegate(),
    SimpleEvent.increment, void delegate(int)
);
SimpleMediator mediator;

// Initialize a counter
int counter;

// Bind some events to the mediator.
mediator.on!(SimpleEvent.reset)(() {
    counter = 0;
});

mediator.on!(SimpleEvent.increment)((int amount) {
    counter += amount;
});

// Make sure nothing happens while the machine is not running.
// The listeners are only ran if the beforeEach hooks all return true.
mediator.beforeEach ~= (SimpleEvent channelName) {
    return channelName == SimpleEvent.reset || machine.state == SimpleState.running;
};

// Bind some events to the machine state changes.
machine.on!(SimpleState.stopped)(() {
    mediator.emit!(SimpleEvent.reset);
});

// Experiment with different operations.
machine.go!(SimpleState.running)();
mediator.emit!(SimpleEvent.increment)(5);
mediator.emit!(SimpleEvent.increment)(3);

assert(counter == 8, "The counter has not incremented");

machine.go!(SimpleState.stopped)();
assert(counter == 0, "The counter was not reset by the machine");

mediator.emit!(SimpleEvent.increment)(3);
assert(counter == 0, "The counter has incremented despite the machine being stopped");
```
