/**
 * This module implements a heap (in a dynamic array)
 * that stores references to other objects.
 *
 * Author: Ivan A. Moreno Soto
 * Date: April 24, 2019
 */
module datastruct.heap;

/**
 * Node that stores a reference to an object along
 * a scalar to be ordered in a minimum heap.
 */
struct HeapNode(Object, Scalar) {
    Object obj;
    Scalar value;
}

/**
 * Implementation of a minimum heap in a dynamic array.
 */
class Heap(Object, Scalar) {
    private HeapNode!(Object, Scalar)[] contents;
    private int last;

    /**
     * Constructs an empty heap with the given capacity.
     *
     * Params:
     *      initCapacity = Initial capacity of the heap.
     */
    this(size_t initCapacity)
    {
        contents.length = initCapacity;
        last = -1;
    }

    /**
     * Returns the index of i's parent.
     */
    private auto parent(int i) {
        return (i - 1)/2;
    }

    /**
     * Returns the index of i's left child.
     */
    private auto left(int i) {
        return 2*i + 1;
    }

    /**
     * Returns the index of i's right child.
     */
    private auto right(int i) {
        return 2*i + 2;
    }

    /**
     * Pushes the given index up in the heap to maintain the properties.
     */
    private void pushUp(int index)
    {
        if(index > 0 && contents[parent(index)].value > contents[index].value) {
            auto temp = contents[index];
            contents[index] = contents[parent(index)];
            contents[parent(index)] = temp;

            pushUp(parent(index));
        }
    }

    /**
     * Pushes the given index down in the heap to maintain the properties.
     */
    private void pushDown(int index)
    {
        int next;

        if(left(index) <= last || right(index) <= last) {
            // If index has both children.
            if(right(index) <= last) {
                if(contents[left(index)].value < contents[right(index)].value)
                    next = left(index);
                else
                    next = right(index);
            } else {
                // If index only has a left children.
                next = left(index);
            }

            if(contents[index].value > contents[next].value) {
                // Swaping the contents.
                auto temp = contents[index];
                contents[index] = contents[next];
                contents[next] = temp;

                pushDown(next);
            }
        }
    }

    /**
     * Inserts a new element into the heap.
     *
     * Params:
     *      obj = Reference to the object that needs to be stored.
     *      value = Scalar to order the new element
     */
    public void insert(ref Object obj, Scalar value)
    {
        if(last + 1 == contents.length) {
            contents.length *= 2;
        }

        last++;
        contents[last] = HeapNode!(Object, Scalar)(obj, value);
        pushUp(last);
    }

    /**
     * Returns the top element of the heap while also removing it
     * from the heap.
     *
     * Throws: Exception if the heap is empty.
     */
    public Object deleteTop()
    {
        import std.stdio: writeln;

        import std.exception: enforce;
        enforce(!isEmpty, "Cannot remove from an empty heap.");

        auto topObject = contents[0].obj;
        // Removing the top.
        contents[0] = contents[last];
        last--;
        pushDown(0);

        return topObject;
    }

    /**
     * Returns the object stored at the top of the heap.
     *
     * Throws: Exception if the heap is empty.
     */
    public ref Object top() @property
    {
        import std.exception: enforce;
        enforce(!isEmpty, "Cannot see top of an empty heap.");

        return contents[0].obj;
    }

    /**
     * Returns the current size of the heap.
     */
    public size_t size() const @property
    {
        return last + 1;
    }

    /**
     * Returns the current capacity of the heap.
     */
    public size_t capacity() const @property
    {
        return contents.capacity;
    }

    /**
     * Returns true if the heap is empty, false otherwise.
     */
    public bool isEmpty() const @property
    {
        return last == -1;
    }
}
