# subscribe.d

A minimalistic library providing eventing-related structures.

There are three modules in the package (all are publicly imported using `import subscribed`:

## Documentation

A ddox-generated documentation with example usage can be found [here](http://ivasilev.net/docs/subscribed/index.html).

## modules

### `subscribed.event`

An event structure representing a one-to-many function/delegate relationship. Events are basically collections of listeners (either functions, delegates or thread ids) that have the same signature. Events are called like functions (via `opCall`) and return arrays, corresponding to the return values of individual listeners. Another cool feature is synchronizing thread outputs in a parallel pipeline.

#### Use case

The module provides C#-like events for managing proper change propagation between different components of a program.

### `subscribed.mediator`

A simple implementation of the mediator pattern. Basically an event hash table with beforeEach/afterEach hooks. A more structured approach to the pub-sub module from the initial implementation.

#### Use case

Imagine a world where numerous program components communicate across threads without even knowing about each other.

### `subscribed.event_machine`

A structure representing a finite state automaton where by default any state (except for the initial one) can be reached from any other state at any time. Each state has an event that is triggered upon transitioning to it. State-dependent transitions should be implemented using beforeEach/afterEach hooks.

The main difference between the mediator and the event machine is that the former can dynamically add new listeners but does not keep track of any state and simply routes events.

#### Use case

The module is intended for simplifying development of persistently running applications. Most components of a long-running program have multiple possible states and implementing switching between states without some publish-subscribe mechanism generally does not scale well. Consider the case bellow:
