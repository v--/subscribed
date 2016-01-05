# subscribe.d

A minimalistic event and event machine library.

There are two modules in the package (both are publicly imported using `import subscribed`:

## Documentation

A ddox-generated documentation with example usage can be found [here](http://ivasilev.net/docs/subscribed/index.html).

## modules

### `subscribed.event`

An event structure representing a one-to-many function/delegate relationship. Events are basically collections of listeners (either functions or delegates) that have the same signature. Events are called like functions (via `opCall`) and return arrays, corresponding to the return values of individual listeners.

#### Use case

The module provides C#-like events for managing proper change propagation between different components of a program.

### `subscribed.event_machine`

A structure representing a complete finite automaton with a singleton alphabet - any state (except for the initial one) can be reached from any other state at any time. Each state has an event that is triggered upon transitioning to it.

#### Use case

The module is intended for simplifying development of persistently running applications. Most components of a long-running program have multiple possible states and implementing switching between states without some publish-subscribe mechanism generally does not scale well. Consider the case bellow:

## Simple example

```d
void playMusic()
{
    // Magic
}

void showLyrics()
{
    // Magic
}

void exit()
{
    // Magic
}

alias Player = EventMachine!(["Play", "Stop"], void function());

Player player;
player.subscribe(Player.State.Play, &playMusic);
player.subscribeToPlay(&showLyrics);
player.subscribeToStop(&exit);

// To start the player
player.goToPlay();

// To stop the player
player.goToStop();
```

## pub-sub

The initial version of the subscribe.d included a pub-sub module. It provided a unified interface for calling events via scoped `publish` and `subscribe` functions. It provided no real benefit over using events directly, except for a little syntax sugar.

The module was removed in version 1.2.

## TODO

* Make events synchronize across multiple threads.
