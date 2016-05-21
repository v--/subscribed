// A simple mediator implementation.
module subscribed.mediator;

import std.traits : isCallable;

import subscribed.support;
import subscribed.event;

/// A helper structure for statically creating mediator channels.
struct Channel
{
    import std.traits : fullyQualifiedName;
    /**
     * Infers channel data from a callable and a string.
     *
     * Params:
     *  name = The key that will be used to identify the channel.
     *  Type = The callable type to use for the channel.
     *
     * Returns:
     *  The inferred channel information.
     */
    @safe static Channel infer(string name, Type)()
        if (isValidIdentifier(name) && isCallable!Type)
    {
        import std.traits : ParameterTypeTuple, moduleName;
        import std.string : format;
        string[] imports;

        foreach (paramType; ParameterTypeTuple!Type)
            static if (__traits(compiles, moduleName!paramType))
                imports ~= `import %1$s : %2$s;`.format(moduleName!paramType, paramType.stringof);

        return Channel(name, Type.stringof, imports);
    }

    /// The name of the channel.
    string name;

    /// A string containing the type of the channel.
    string type;

    /// The imports and that sould be imported.
    string[] imports;
}

/// A channel name an function type can be inferred.
unittest
{
    immutable channel = Channel.infer!("name", void function(Channel));
    assert(channel.name == "name", "Could not infer the channel name.");
    assert(channel.type == "void function(Channel)", "Could not infer the channel type.");
    assert(channel.imports == ["import subscribed.mediator : Channel;"], "Could not infer the required imports.");
}

/**
 * A simple mediator implementation.
 * More precisely, an event collection with a unified interface and beforeEach/afterEach hooks.
 *
 * Params:
 *  channels = A dynamic array of Channel objects.
 *
 * Bugs:
 *  Because of the way the mediator is implemented (through string mixins), user-defined structures will not work without cyclic imports.
 *  This may cause some problems, most notably with static constructors.
 */
struct Mediator(Channel[] channels)
{
    import std.algorithm : all, map;
    import std.string : format, split, indexOf;
    import std.array : array, join;

    /// The hook to be executed before any transition. If false is returned, the no transition occurs.
    Event!(bool delegate()) beforeEach;

    /// The hook to be executed after a successful transition.
    Event!(void delegate()) afterEach;

    version (D_Ddoc)
    {
        alias EventType = VoidEvent;

        /**
         * A function for appending listeners to the channel event.
         *
         * Params:
         *  channel = The channel whose event to subscribe to.
         *  listeners = The listeners to append.
         *
         * See_Also:
         *  subscribed.event.Event.append
         */
        @safe void on(string channel)(EventType.ListenerType[] listeners...);

        /**
         * A function for removing listeners from the channel event.
         *
         * Params:
         *  channel = The channel whose event to remove from.
         *  listeners = The listeners to remove.
         *
         * See_Also:
         *  subscribed.event.Event.append
         */
        @safe void off(string channel)(EventType.ListenerType[] listeners...);

        /**
         * Calls all the registered listeners for the channel in order.
         *
         * Params:
         *  channel = The channel to emit a message to.
         *  params = The param tuple to call the listeners with.
         *
         * Returns:
         *  An array of results from the listeners.
         *  If $(DDOC_PSYMBOL EventType.ReturnType) is void, then this function also returns void.
         *
         * See_Also:
         *  subscribed.event.Event.call
         */
        @safe EventType.ReturnType emit(string channel)(EventType.ParamTypes params);
    }

    mixin(q{
            ~this()
            {
                %s
            }
        }.format(channels
            .map!((Channel channel) => "_%s.destroy();".format(channel.name))
            .array
            .join("\n")
        )
    );

    mixin(channels.map!((Channel channel) {
        return q{
            %3$s

            private
            {
                alias %2$sEventType = Event!(%1$s);
                %2$sEventType _%2$s;
            }

            @safe void on(string channel: "%2$s")(%2$sEventType.ListenerType[] listeners...)
            {
                _%2$s.append(listeners);
            }

            @safe void off(string channel: "%2$s")(%2$sEventType.ListenerType[] listeners...)
            {
                _%2$s.remove(listeners);
            }

            %2$sEventType.ReturnType emit(string channel: "%2$s")(%2$sEventType.ParamTypes params)
            {
                foreach (condition; beforeEach()) {
                    if (!condition) {
                        static if (is(%2$sEventType.ReturnType == void))
                            return;
                        else
                            return %2$sEventType.ReturnType.init;
                    }
                }

                static if (is(%2$sEventType.ReturnType == void))
                {
                    _%2$s.call(params);
                    afterEach();
                }
                else
                {
                    auto result = _%2$s.call(params);
                    afterEach();
                    return result;
                }
            }
        }.format(channel.type, channel.name, channel.imports.join("\n"));
    }).array.join("\n"));
}

/// The mediator can subscribe, unsubscribe and broadcast events.
unittest
{
    Mediator!([
        Channel.infer!("inc", void delegate()),
        Channel.infer!("dec", void delegate())
    ]) mediator;

    int counter;

    void increment()
    {
        counter++;
    }

    void decrement()
    {
        counter--;
    }

    mediator.on!"inc"(&increment);
    mediator.on!"dec"(&decrement);

    assert(counter == 0, "Mediator functions are called before any action is performed.");
    mediator.emit!"inc";
    assert(counter == 1, "The mediator does not call one of it's functions.");
    mediator.emit!"dec";
    assert(counter == 0, "The mediator does not call one of it's functions.");

    mediator.beforeEach ~= () => false;

    assert(counter == 0, "The beforeEach hook does not work.");
    mediator.emit!"inc";
    assert(counter == 0, "The beforeEach hook does not work.");
    mediator.emit!"dec";
    assert(counter == 0, "The beforeEach hook does not work.");

    mediator.beforeEach.clear();

    mediator.off!"inc"(&increment);
    mediator.off!"dec"(&decrement);

    assert(counter == 0, "The mediator called one of it's functions while unregistering them.");
    mediator.emit!"inc";
    assert(counter == 0, "The mediator did not remove a listener.");
    mediator.emit!"dec";
    assert(counter == 0, "The mediator did not remove a listener.");
}
