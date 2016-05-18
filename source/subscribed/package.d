/**
 * A minimalistic library providing eventing-related structures.
 * Authors: Ianis G. Vasilev `<mail@ivasilev.net>`
 * Copyright: Copyright © 2015-2016, Ianis G. Vasilev
 * License: BSL-1.0
 */
module subscribed;

public import subscribed.event;
public import subscribed.event_machine;
public import subscribed.mediator;

///
unittest
{
    // Create and instantiate a simple finite-state machine structure.
    alias SimpleMachine = EventMachine!(["Running", "Stopped"]);
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
    mediator.beforeEach ~= () {
        return machine.state == SimpleMachine.State.Running;
    };

    // Bind some events to the machine state changes.
    machine.onStopped(() {
        mediator.emit!"reset";
    });

    // Experiment with different operations.
    machine.goToRunning();
    mediator.emit!"increment"(5);
    mediator.emit!"increment"(3);
    assert(counter == 8, "The counter has not incremented.");

    machine.goToStopped();
    assert(counter == 0, "The counter was not reset by the machine.");

    mediator.emit!"increment"(3);
    assert(counter == 0, "The counter has incremented despite the machine being stopped.");
}
