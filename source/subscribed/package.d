/// A minimalistic library providing eventing-related structures.
module subscribed;

public import subscribed.event;
public import subscribed.event_machine;
public import subscribed.mediator;

///
unittest
{
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
}
