/// A minimalistic library providing eventing-related structures.
module subscribed;

/// <a href="./subscribed.event.html">Go to the docs for the Event struct.</a>
public import subscribed.event;

/// <a href="./subscribed.event_machine.html">Go to the docs for the EventMachine struct.</a>
public import subscribed.event_machine;

/// <a href="./subscribed.mediator.html">Go to the docs for the Mediator struct.</a>
public import subscribed.mediator;

///
unittest
{
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
}
