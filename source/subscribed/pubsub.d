module subscribed.pubsub;
import subscribed.event;

mixin template PubSubChannel(string name, callableType = void function()) if (isCallable!callableType)
{
    private Event!callableType event;

    void subscribe(string channel: name)(callableType callable)
    {
        event ~= callable;
    }

    auto publish(string channel: name)(event.parameterTypes args)
    {
        static if (is(event.returnType == void))
            event(args);
        else
            return event(args);
    }

    bool unsubscribe(string channel: name)(callableType callable)
    {
        return event -= callable;
    }
}

package version (unittest)
{
    bool flag;

    void changeFlag()
    {
        flag ^= 1;
    }

    int f(int i)
    {
        return i;
    }

    mixin PubSubChannel!("test", int function(int));

    void tests()
    {
        subscribe!"test"(&f);
        assert(publish!"test"(1) == [1]);
        assert(unsubscribe!"test"(&f));
        assert(!unsubscribe!"test"(&f));

        mixin PubSubChannel!"change";

        subscribe!"change"(&changeFlag);
        publish!"change";
        assert(flag);
        publish!"change";
        assert(!flag);

        subscribe!"change"(&changeFlag);
        publish!"change";
        assert(!flag);

        assert(unsubscribe!"change"(&changeFlag));
        publish!"change";
        assert(!flag);
    }
}

unittest
{
    tests;
}
