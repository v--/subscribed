# subscribe.d

A minimalistic event and eventmachine library.

There are two modules in the package (both are publicly imported using `import subscribed`:

* `subscribed.event`: An event structure representing a one-to-many function/delegate relationship. Events are basically collections of listeners (either functions or delegates) that have the same signature. Events are called like functions (via `opCall`) and return arrays, corresponding to the return values of individual listeners.

## TODO

* Make the library available across multiple threads
