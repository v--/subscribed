module subscribed.event;
import std.container: DList;
import std.algorithm: find;
import std.array: array;

package interface IEvent
{
    @property void* ptr();
    @property string argTypes();
}

class Event(ReturnType, ArgTypes...): IEvent
{
    alias delegateType = ReturnType delegate(ArgTypes);
    private DList!(delegateType) delegates;

    @property void* ptr()
    {
        return cast(void*)this;
    }

    @property string argTypes()
    {
        return ArgTypes.stringof;
    }

    @property subscribers()
    {
        return array(delegates[]);
    }

    static if (is(ReturnType == void))
    {
        void opCall(ArgTypes args)
        {
            foreach (del; delegates)
                del(args);
        }
    }

    else
    {
        ReturnType[] opCall(ArgTypes args)
        {
            ReturnType[] result;

            foreach (del; delegates)
                result ~= del(args);

            return result;
        }
    }

    void opOpAssign(string s)(delegateType del) if (s == "~")
    {
        delegates ~= del;
    }

    bool opOpAssign(string s)(delegateType del) if (s == "-")
    {
        auto matches = find!(f => f == del)(delegates[]);

        if (matches.empty)
            return false;

        delegates.remove(matches);
        return true;
    }
}

alias VoidEvent = Event!void;

unittest
{
    bool value;

    void changeValue()
    {
        value ^= 1;
    }

    int add(int a, int b)
    {
        return a + b;
    }

    int multiply(int a, int b)
    {
        return a * b;
    }

    auto event = new Event!(int, int, int);
    assert(event(5, 5) == []);
    event ~= &add;
    assert(event(5, 5) == [10]);
    event ~= &multiply;
    assert(event(5, 5) == [10, 25]);
    assert(event.subscribers.length == 2);
    assert(event -= &multiply);
    assert(event.subscribers.length == 1);

    auto voidEvent = new VoidEvent;
    voidEvent ~= &changeValue;
    assert(!value);
    voidEvent();
    assert(value);
}
