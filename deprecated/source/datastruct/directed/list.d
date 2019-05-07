/**
 * This module implements doubly-linked lists for vertices and arcs to be used
 * in the module datastruct.directed.digraph. These structs and classes are only
 * meant to be manipulated by the classes Digraph, and Network; effectively
 * being private outside of the package 'datastruct.directed'.
 *
 * Author: Ivan A. Moreno Soto
 * Date: April 14, 2019
 */
module datastruct.directed.list;

/**
 * Struct that implements a container for vertices of a directed graph (or network).
 * It has algorithm-specific attributes, all of which are indicated.
 *
 * VType is the type for the vertex identifier.
 * EType is the type for the arc's weight/flow/minimum.
 */
struct DVertex(VType, EType) {
    // Generic attributes.
    VType name;
    size_t inDegree, outDegree;
    DVertex!(VType, EType)* next, prev;
    ArcList!(VType, EType) outArcs, inArcs;
    int touched; // Whatever the algorithm needs it to be.

    // Attributes for Ford-Fulkerson. Only meant to be used in a Network instance.
    DVertex!(VType, EType)* ant; // Previous vertex in a chain.
    Arc!(VType, EType)* antArc; // Previous arc in a chain.
    bool opperation; // true if flow is being added, false if it's being taken away.
    EType chainCapacity;

    /**
     * Initializes a new instance of a DVertex.
     *
     * Params:
     *      name_ = Identifier for this vertex
     *      next_ = Pointer to the next vertex on the list.
     *      prev_ = Pointer to the previous vertex on the list.
     */
    this(VType name_, DVertex!(VType, EType)* next_, DVertex!(VType, EType)* prev_)
    {
        this.name = name_;
        this.outDegree = this.inDegree = 0;
        this.prev = prev_;
        this.next = next_;
        this.outArcs = new ArcList!(VType, EType);
        this.inArcs = new ArcList!(VType, EType);

        this.ant = null;
        this.antArc = null;
        this.opperation = false;
        this.touched = 0;
    }

    /**
     * Provides a shorthand to the first element in the list of arcs that come out of this vertex.
     */
    auto begOutArcs() @property
    {
        return outArcs.head;
    }

    /**
     * Provides a shorthand to the first element in the list of arcs that arrive at this vertex.
     */
    auto begInArcs() @property
    {
        return inArcs.head;
    }

}

/**
 * Implements a container for whatever attributes a Digraph/Network need from an arc.
 * As such, it has attributes that a Digraph must ignore, like flow and minimum.
 *
 * VType is the type for the vertex identifier.
 * EType is the type for the arc's weight/flow/minimum.
 */
struct Arc(VType, EType) {
    EType weight, flow, minimum;
    VType opposite; // Shorthand for the identifier of the opposite end of this arc.
    DVertex!(VType, EType)* source, terminus; // Of course we're going to optimize the ever living crap out of this.
    Arc!(VType, EType)* next, prev;

    /**
     * Initializes a new arc. Special treatments are indicated.
     *
     * Params:
     *      weight_ = Weight of the arc (Digraph) or maximum flow capacity (Network)
     *      flow_ = Current amount of flow (only for Networks). A Digraph must send 0
     *      minimum_ = Minimum amount of flow that must pass (only for Networks). A Digraph must send 0
     *      opposite_ = Identifier of the other end of this arc
     *      source_ = Pointer to the source of the arc
     *      terminus_ = Pointer to the terminus of the arc
     *      next_ = Pointer to the next arc of the list
     *      prev_ = Pointer to the previous arc of the list
     */
    this(EType weight_, EType flow_, EType minimum_, VType opposite_,
        DVertex!(VType, EType)* source_, DVertex!(VType, EType)* terminus_,
        Arc!(VType, EType)* next_, Arc!(VType, EType)* prev_)
    {
        this.opposite = opposite_;
        this.weight = weight_;
        this.flow = flow_;
        this.minimum = minimum_;
        this.source = source_;
        this.terminus = terminus_;
        this.next = next_;
        this.prev = prev_;
    }
}

/**
 * Implements a doubly-linked list of vertices that can add elements at the
 * beginning and end in constant time.
 *
 * VType is the type for the vertex identifier.
 * EType is the type for the arc's weight/flow/minimum.
 */
class DVertexList(VType, EType) {
package:
    size_t length;
    DVertex!(VType, EType)* head, tail;

    /**
     * Constructs a new empty list.
     */
    this()
    {
        length = 0;
        head = tail = null;
    }

    /**
     * Adds an element at the beginning of the list.
     *
     * Params:
     *      value = Identifier for the new vertex.
     */
    void add(VType value)
    {
        auto newNode = new DVertex!(VType, EType)(value, head, null);

        if(length == 0) {
            tail = newNode;
        } else {
            head.prev = newNode;
        }

        head = newNode;
        length++;
    }

    /**
     * Adds an element at the end of the list.
     *
     * Params:
     *      value = Identifier for the new vertex.
     */
    void append(VType value)
    {
        auto newNode = new DVertex!(VType, EType)(value, null, tail);

        if(length == 0) {
            head = newNode;
        } else {
            tail.next = newNode;
        }

        tail = newNode;
        length++;
    }

    /**
     * Removes the indicated vertex from the list. If the vertex doesn't exist,
     * it does nothing. It doesn't throw exceptions.
     *
     * Params:
     *      value = Identifier of the vertex that needs to be removed
     */
    void remove(VType value)
    {
        for(auto node = head; node !is null; node = node.next) {
            if(node.name == value) {
                if(node.prev !is null) node.prev.next = node.next;
                if(node.next !is null) node.next.prev = node.prev;

                if(node == head) head = head.next;
                if(node == tail) tail = tail.prev;

                length--;
                break;
            }
        }
    }

    /**
     * Searches for a particular vertex and returns a pointer to it.
     *
     * Params:
     *      name = Identifier of the vertex of interest
     *
     * Returns: Pointer to the vertex if it's found, null otherwise.
     */
    auto peek(VType name)
    {
        for(auto node = head; node !is null; node = node.next) {
            if(node.name == name) {
                return node;
            }
        }

        return null;
    }

    /**
     * Looks for a particular vertex in the list.
     *
     * Params:
     *      name = Identifier of the vertex of interest
     *
     * Returns: true if the vertex it's found, false otherwise.
     */
    bool search(VType value)
    {
        for(auto node = head; node !is null; node = node.next) {
            if(node.name == value) {
                return true;
            }
        }

        return false;
    }

    /**
     * Writes the attributes of the vertices (and their arcs) in the list to
     * the standard output.
     */
    void print()
    {
        import std.stdio: write;
        import std.string: format;

        for(auto node = head; node !is null; node = node.next) {
            write(format("%s(deg+: %s; deg-: %s): ", node.name, node.outDegree, node.inDegree));
            for(auto arc = node.outArcs.head; arc !is null; arc = arc.next) {
                write(format("%s(f:%s, w:%s, r:%s) ", arc.opposite, arc.flow, arc.weight, arc.minimum));
            }
            write('\n');
        }
    }

    /**
     * Shorthand for the head of the list.
     */
    auto beginning() @property
    {
        return head;
    }

    /**
     * Returns the current number of vertices in the list.
     */
    auto size() const @property
    {
        return length;
    }

    /**
     * Returns true if the list is empty, false otherwise.
     */
    bool isEmpty() @property
    {
        return length == 0;
    }
}

/**
 * Implements a doubly-linked list of arcs that can add elements at the end in
 * constant time.
 *
 * VType is the type for the vertex identifier.
 * EType is the type for the arc's weight/flow/minimum.
 */
class ArcList(VType, EType) {
package:
    size_t length;
    Arc!(VType, EType)* head, tail;

    /**
     * Constructs a new empty list.
     */
    this()
    {
        length = 0;
        head = tail = null;
    }

    /**
     * Adds an arc to the end of the list with the given attributes.
     *
     * Params:
     *      opposite = Identifier of the opposite vertex
     *      weight = Weight of the new arc
     *      minimum = Minimum restriction for the new arc (for Networks, Digraphs must send 0)
     *      flow = Amount of flow for the new arc (for Networks, Digraphs must send 0)
     *      sourceVertex = Pointer to the source of the new arc
     *      terminusVertex = Pointer to the terminus of the new arc
     */
    void append(VType opposite, EType weight, EType minimum, EType flow,
        DVertex!(VType, EType) *sourceVertex, DVertex!(VType, EType) *terminusVertex)
    {
        auto newNode = new Arc!(VType, EType)(weight, flow, minimum, opposite,
            sourceVertex, terminusVertex, null, tail);

        if(length == 0) {
            head = newNode;
        } else {
            tail.next = newNode;
        }

        tail = newNode;
        length++;
    }

    /**
     * Removes the indicated arc from the list. If the arc doesn't exist,
     * it does nothing. It doesn't throw exceptions.
     *
     * Params:
     *      opposite = Identifier of the opposite vertex of the arc
     *      weight = Weight the arc must have
     */
    void remove(VType opposite, EType weight)
    {
        for(auto node = head; node !is null; node = node.next) {
            if(node.opposite == opposite && node.weight == weight) {
                if(node.prev !is null) node.prev.next = node.next;
                if(node.next !is null) node.next.prev = node.prev;

                if(node == head) head = head.next;
                if(node == tail) tail = tail.prev;

                length--;
                break;
            }
        }
    }

    /**
     * Searches for an arc to a particular vertex with a particular weight and
     * returns a pointer to it.
     *
     * Params:
     *      opposite = Identifier of the vertex of interest
     *      weight = Weight the arc must have
     *
     * Returns: Pointer to the arc if it's found, null otherwise.
     */
    auto peek(VType opposite, EType weight)
    {
        for(auto node = head; node !is null; node = node.next) {
            if(node.opposite == opposite && node.weight == weight) {
                return node;
            }
        }

        return null;
    }

    /**
     * Looks for an arc to a particular vertex with a particular weight in the
     * list.
     *
     * Params:
     *      opposite = Identifier of the vertex of interest
     *      weight = Weight the arc must have
     *
     * Returns: true if the arc it's found, false otherwise.
     */
    bool search(VType opposite, EType weight)
    {
        for(auto node = head; node !is null; node = node.next) {
            if(node.opposite == opposite && node.weight == weight) {
                return true;
            }
        }

        return false;
    }

    /**
     * Checks if there's already an arc to a particular vertex. Only meant for use
     * in Network.
     *
     * Params:
     *      opposite = Identifier of the vertex of interest
     *
     * Returns: true if an arc to opposite was found, false otherwise.
     */
    bool isThereAnArcTo(VType opposite)
    {
        for(auto node = head; node !is null; node = node.next) {
            if(node.opposite == opposite) {
                return true;
            }
        }

        return false;
    }

    /**
     * Returns the current number of arcs in the list.
     */
    auto size() const @property
    {
        return length;
    }

    /**
     * Returns true if the list is empty, false otherwise.
     */
    bool isEmpty() @property
    {
        return length == 0;
    }
}
