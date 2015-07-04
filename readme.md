# subscribe.d

This is a simple library for minimalistic in-process pub-sub and event operations.

There are two modules in the package (both can be imported using `import subscribed`:

* `subscribed.event` provides a struct for creating events, which are basically collections of callables (functions or delegates) ("subscribers") that have the same signature. Events are called like functions (via `opCall`) and return arrays, corresponding to the return values of individual functions:
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

// The argument of the Event template is the callable

Event!(int delegate(int, int)) event;
event ~= &add;
event ~= &multiply;
assert(event(5, 5) == [10, 25]);

// For convenience, VoidEvent aliases Event!(void function()) (events, accepting void functions without parameters). Obviously, these events do not return.

VoidEvent event;
event ~= doNothing;
event ~= doNothing;
event();

// You can add the same callable multiple times. When removing it however, all mathing callables get removed.

event -= doNothing; // Returns true, meaning that there were >=1 removed callables
event -= doNothing; // Returns false, meaning that there were no removed callables
assert(event.size == 0); // No subscribers left
assert(event.subscribers == []);

event ~= doNothing;

// You can off course shift and pop callables
event.shift; // Returns doNothing
assert(event.pop == null); // Returns null, because no callables are available

event ~= doNothing;

// In case you want to remove all subscribers:
assert(!event.empty) // The event has one subscriber
assert(event.clear) // Returns true, meaning that there were removed subscribers
```

* `subscribed.pubsub` is based on events and provides functions for sending and receiving any sort of data (generally the transferred data is called a message, although in this context it may be inappropriate to call it so). The module doesn't use any messaging protocol and relies solely on Events to transfer messages, making it fast and easy to use for in-program events. 

```
// To create a channel, simply choose a name and use the template mixin:

mixin PubSubChannel!"change";

// Now in whatever scope you have created the channel, you should be able to subscribe and publish. The global scope is used in this case. The second argument to the mixin is the type of the callable, by default 'void function()'

int f(int i)
{
    return i;
}

subscribe!"test"(&f); // You can only subscribe delegates to the "test" channel, because it is the only one created. This code will not compile, because f is of the wrong type

mixin PubSubChannel!("int", int function(int));

subscribe!"int"(&f);

publish!"int"(1); // Returns [1]

unsubscribe!"int"(&f); // Returns true, meaning that there were removed callables
unsubscribe!"test"(&f); // Returns false, meaning that there were no removed callables
```

## TODO:

* Write a proper documentation
* Find a way to provide an express.js-like routing to channel names
