module subscribed.event;
import std.container: DList;
import std.algorithm: find;
import std.traits: isCallable, isDelegate, ReturnType, ParameterTypeTuple;
import std.array: array;

struct Event(Type) if (isCallable!Type)
{
    private
    {
        DList!(Type) listeners;
        int _size;
    }

    alias type = Type;
    alias returnType = ReturnType!Type;
    alias parameterTypes = ParameterTypeTuple!Type;

    @property size()
    {
        return _size;
    }

    @property subscribers()
    {
        return array(listeners[]);
    }

    @property empty()
    {
        return listeners.empty;
    }

    bool clear()
    {
        auto result = !empty;
        _size = 0;
        listeners.clear;
        return result;
    }

    static if (is(returnType == void))
    {
        auto opCall(parameterTypes args)
        {
            foreach (del; listeners)
                del(args);
        }
    }

    else
    {
        auto opCall(parameterTypes args)
        {
            returnType[] result;

            foreach (del; listeners)
                result ~= del(args);

            return result;
        }
    }

    Type shift()
    {
        if (listeners.empty)
            return null;

        _size -= 1;
        auto front = listeners.front;
        listeners.removeFront;
        return front;
    }

    Type pop()
    {
        if (listeners.empty)
            return null;

        _size -= 1;
        auto back = listeners.back;
        listeners.removeBack;
        return back;
    }

    void opOpAssign(string s)(Type del) if (s == "~")
    {
        _size++;
        listeners ~= del;
    }

    bool opOpAssign(string s)(Type del) if (s == "-")
    {
        auto matches = find!(f => f == del)(listeners[]);

        if (matches.empty)
            return false;

        _size -= array(matches).length;
        listeners.remove(matches);
        return true;
    }
}

alias VoidEvent = Event!(void function());

package version (unittest)
{
    import core.exception;
    import std.exception: Exception, assertThrown;

    bool flag;

    void changeFlag()
    {
        flag ^= 1;
    }

    void tests()
    {
        int add(int a, int b)
        {
            return a + b;
        }

        int multiply(int a, int b)
        {
            return a * b;
        }

        Event!(int delegate(int, int)) event;
        assert(event(5, 5) == []);
        event ~= &add;
        assert(event(5, 5) == [10]);
        event ~= &multiply;
        assert(event(5, 5) == [10, 25]);
        assert(event.size == 2);
        assert(event -= &multiply);
        assert(event.size == 1);
        event.shift;
        assert(event.subscribers == []);
        assert(event.shift == null);

        VoidEvent voidEvent;
        voidEvent ~= &changeFlag;
        assert(!flag);
        voidEvent();
        assert(flag);
        assert(voidEvent.clear);
        assert(voidEvent.empty);
        assert(!voidEvent.clear);
    }
}

unittest
{
    tests;
}
