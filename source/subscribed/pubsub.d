module subscribed.pubsub;
import core.thread: Fiber, Thread, dur;
import subscribed.event;
import std.exception: Exception, assertThrown;
import std.typecons: Tuple;
import std.string: format;

private
{
    IEvent[string] channels;
    enum string errorMessage = "Channel %s uses delegates with arguments %s, not %s";
}

class ChannelTypeException: Exception
{
    this(string channel, string argTypes, string channelType)
    {
        super(errorMessage.format(channel, argTypes, channelType));
    }
}

void publish(T...)(string channel, T params)
{
    alias EventType = Event!(void, T);
    EventType event;

    if (channel !in channels)
        return;

    event = cast(EventType)channels[channel].ptr;

    if (event.argTypes != T.stringof)
        throw new ChannelTypeException(channel, T.stringof, event.argTypes);

    event(params);
}

void subscribe(T...)(string channel, void delegate(T) del)
{
    auto argTypes = T.stringof;
    alias EventType = Event!(void, T);
    EventType event;

    if (channel !in channels)
    {
        event = new EventType;
        event ~= del;
        channels[channel] = event;
        return;
    }

    event = cast(EventType)channels[channel].ptr;

    if (event.argTypes != argTypes)
        throw new ChannelTypeException(channel, argTypes, event.argTypes);

    event ~= del;
}

bool unsubscribe(T...)(string channel, void delegate(T) del)
{
    alias EventType = Event!(void, T);
    EventType event;

    if (channel !in channels)
        return false;

    event = cast(EventType)channels[channel].ptr;

    if (event.argTypes != T.stringof)
        throw new ChannelTypeException(channel, T.stringof, event.argTypes);

    return event -= del;
}

void destroyChannel(string channel)
{
    if (channel in channels) {
        channels[channel].destroy;
        channels.remove(channel);
    }
}

unittest
{
    bool value;

    void changeValue()
    {
        value ^= 1;
    }

    void f(int a) {}
    void g(int a, int b) {}
    void h(string a) {}

    subscribe("test", &f);
    assertThrown!ChannelTypeException(subscribe("test", &g));
    assertThrown!ChannelTypeException(subscribe("test", &h));
    publish("test", 1);
    assertThrown!ChannelTypeException(publish("test", 1, 2));
    assert(unsubscribe("test", &f));
    assert(!unsubscribe("test", &f));

    subscribe("change", &changeValue);
    publish("change");
    assert(value);
    publish("change");
    assert(!value);

    subscribe("change", &changeValue);
    publish("change");
    assert(!value);

    destroyChannel("change");
    publish("change");
    assert(!value);
}
