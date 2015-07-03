# subscribe.d

This is a simple library for minimalistic in-process pub-sub and event operations.

There are two modules in the package (both can be imported using `import subscribed`:

* `subscribed.event` provides a class for creating events, which are basically collections of delegates ("subscribers") that have the same signature. Events are called like functions (`opCall`) and return arrays, corresponding to the return values of individual functions:
```
import subscribed.event;

int add(int a, int b)
{
    return a + b;
}

int multiply(int a, int b)
{
    return a * b;
}

void doNothing() {}

// The first argument of the constructor specifies the return type, the rest specify the types of arguments this event should expect from it's delegates

auto event = new Event!(int, int, int);
event ~= &add;
event ~= &multiply;
assert(event(5, 5) == [10, 25]);
event.destroy

// For convenience, VoidEvent aliases Event!void (events, accepting void delegates without parameters). Obviously, these events do not return.

event = new VoidEvent;
event ~= doNothing;
event ~= doNothing;
event();

// You can add the same delegate multiple times. When removing it however, all mathing delegates get removed.

event -= doNothing; // Returns true, meaning that there were >=1 removed delegates
event -= doNothing; // Returns false, meaning that there were no removed delegates
assert(event.subscribers.length == 0); // No subscribers left

event ~= doNothing;

// You can off course shift and pop delegates
event.shift; // Doesn't throw
assertThrown!AssertError(event.shift); // Throws and AssertError, because there is nothing to return
```

* `subscribed.pubsub` is based on events and provides functions for sending and receiving any sort of data (generally the transferred data is called a message, although in this context it may be inappropriate to call it so). The module doesn't use any messaging protocol and relies solely on Events to transfer messages, making it fast and easy to use for in-program events. Publishing data does not return, thus making all return values void.

```
void f(int a) {}
void g(int a, int b) {}
void h(string a) {}

subscribe("test", &f); // From now on, all delegates, subscribing to the "test" channel should have the same type as f: void function(int)

publish("test", 1); // Transfers 1 to all subscribed delegates, currently only f. Publishing to an event without subscribers simply does nothing, regardless of the "message".

publish("test", 1, 2)); // Throws an ChannelTypeException, because the data transmitted does not match what the underlying event expects

unsubscribe("test", &f); // Returns true, meaning that there were >=1 removed delegates
unsubscribe("test", &f); // Returns false, meaning that there were no removed delegates

destroyChannel("test"); // Destroys the underlying event, making it possible to subscribe delegates with a different signature
```
