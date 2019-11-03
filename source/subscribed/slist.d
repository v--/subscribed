/// An event structure representing a one-to-many function/delegate relationship.
module subscribed.slist;

import std.experimental.allocator;
import std.exception : enforce, basicExceptionCtors;

///
class SListException : Exception
{
    ///
    mixin basicExceptionCtors;
}

/**
 * A singly linked list based on theAllocator from std.experimental.allocator.
 *
 * Params:
 *  T = The type of the list items.
 */
struct SList(T)
{
    private
    {
        SListNode!T* payload;
        void assertNonEmpty() const
        {
            if (empty)
                throw new SListException("The list is empty");
        }

        struct SListNode(T)
        {
            SListNode!T* next;
            T value;
        }
    }

    this(this)
    {
        if (payload is null)
            return;

        SListNode!T* srcNode = payload;
        SListNode!T* destNode = null;
        payload = null;

        while (srcNode !is null)
        {
            auto newNode = theAllocator.make!(SListNode!T);
            newNode.value = srcNode.value;

            if (destNode !is null)
                destNode.next = newNode;

            destNode = newNode;
            srcNode = srcNode.next;

            if (payload is null)
                payload = destNode;
        }
    }

    ~this()
    {
        auto node = payload;

        while (node !is null)
        {
            auto nextNode = node.next;
            theAllocator.dispose(node);
            node = nextNode;
        }
    }

    /**
     * A boolean property indicating whether there are list items.
     * Part of the bidirectional range interface.
     */
    bool empty() const
    {
        return payload is null;
    }

    /**
     * Get the front element or throw an error if the list is empty.
     * Part of the bidirectional range interface.
     */
    T front() const
    {
        assertNonEmpty();
        return payload.value;
    }

    /**
     * Pop the front element or throw an error if the list is empty.
     * Part of the bidirectional range interface.
     */
    void popFront()
    {
        assertNonEmpty();
        auto newNode = payload.next;
        theAllocator.dispose(payload);
        payload = newNode;
    }

    ///
    void insertFront(T value)
    {
        auto node = theAllocator.make!(SListNode!T);
        node.value = value;
        node.next = payload;
        payload = node;
    }

    /**
     * Get the back element or throw an error if the list is empty.
     * Part of the bidirectional range interface.
     */
    T back() const
    {
        assertNonEmpty();
        SListNode!T* last = cast(SListNode!T*)payload;

        while (last.next !is null)
            last = last.next;

        return last.value;
    }

    /**
     * Pop the back element or throw an error if the list is empty.
     * Part of the bidirectional range interface.
     */
    void popBack()
    {
        assertNonEmpty();
        auto last = payload;

        while (last.next !is null && last.next.next !is null)
            last = last.next;

        theAllocator.dispose(last.next);
        last.next = null;
    }

    ///
    void insertBack(T value)
    {
        auto newNode = theAllocator.make!(SListNode!T);
        newNode.value = value;

        if (payload is null)
        {
            payload = newNode;
        }
        else
        {
            auto last = payload;

            while (last.next !is null)
                last = last.next;

            last.next = newNode;
        }
    }

    /**
     * Remove all occurrences of a given value.
     *
     * Params:
     *  value = the value to remove.
     *
     * Returns:
     *  The number of items removed from the list.
     */
    size_t removeAll(T value)
    {
        SListNode!T* node = payload;
        SListNode!T* prev = null;
        size_t removedCount = 0;

        while (node !is null)
        {
            auto next = node.next;

            if (node.value == value)
            {
                if (node == payload)
                    payload = next;
                else
                    prev.next = next;

                theAllocator.dispose(node);
                removedCount++;
            }
            else
                prev = node;

            node = next;
        }

        return removedCount;
    }

    ///
    void clear()
    {
        while (!empty)
            popFront();
    }

    /**
     * Copies the list to allow multiple range-like iteration.
     * Part of the bidirectional range interface.
     */
    auto save()
    {
        return this;
    }

    ///
    auto opSlice()
    {
        return this;
    }
}
