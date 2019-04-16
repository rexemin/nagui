module datastruct.undirected.glist;

import std.stdio;
import std.string;
import std.exception: enforce;

struct Vertex(VType, EType) {
    VType name;
    size_t degree;
    EdgeList!(VType, EType) edges;

    Vertex!(VType, EType) *next;
    Vertex!(VType, EType) *prev;
}

struct Edge(VType, EType) {
    EType weight;
    VType terminus_name;
    Vertex!(VType, EType) *source;
    Vertex!(VType, EType) *terminus;

    Edge!(VType, EType) *next;
    Edge!(VType, EType) *prev;
}

class VertexList(VType, EType) {
private:
    size_t length;
    Vertex!(VType, EType) *head;
    Vertex!(VType, EType) *tail;
public:
    this()
    {
        length = 0;
        head = tail = null;
    }

    void add(VType v)
    {
        auto new_node = new Vertex!(VType, EType);
        new_node.name = v;
        new_node.degree = 0;
        new_node.prev = null;
        new_node.next = head;
        new_node.edges = new EdgeList!(VType, EType);

        if(length == 0) {
            tail = new_node;
        } else {
            head.prev = new_node;
        }
        head = new_node;
        length++;
    }

    void append(VType v)
    {
        auto new_node = new Vertex!(VType, EType);
        new_node.name = v;
        new_node.degree = 0;
        new_node.prev = tail;
        new_node.next = null;
        new_node.edges = new EdgeList!(VType, EType);

        if(length == 0) {
            head = new_node;
        } else {
            tail.next = new_node;
        }

        tail = new_node;
        length++;
    }

    void remove(VType v)
    {
        int index = 0;
        for(auto node = head; node !is null; node = node.next, index++) {
            if(node.name == v) {
                if(node == head) {
                    popFirst();
                    break;
                } else if(node == tail) {
                    popLast();
                    break;
                }

                node.prev.next = node.next;
                node.next.prev = node.prev;
                length--;
                break;
            }
        }
    }

    VType popFirst()
    {
        enforce(length > 0, "The list is empty. Cannot pop first element.");

        auto value = head.name;
        head = head.next;
        length--;

        if(head !is null) {
            head.prev = null;
        } else {
            tail = null;
        }

        return value;
    }

    VType popLast()
    {
        enforce(length > 0, "The list is empty. Cannot pop last element.");

        auto value = tail.name;
        tail = tail.prev;
        length--;

        if(tail !is null) {
            tail.next = null;
        } else {
            head = null;
        }

        return value;
    }

    auto peek()
    {
        return head;
    }

    auto peek(VType name)
    {
        for(auto node = head; node !is null; node = node.next) {
            if(node.name == name) {
                return node;
            }
        }

        return null;
    }

    bool search(VType v)
    {
        return getIndex(v) != -1;
    }

    auto getIndex(VType v)
    {
        if(length == 0) {
            return -1;
        }

        int index = 0;
        for(auto node = head; node !is null; node = node.next, index++) {
            if(node.name == v) {
                return index;
            }
        }

        // Not found.
        return -1;
    }

    auto size() const @property
    {
        return length;
    }

    bool isEmpty() @property
    {
        return length == 0;
    }

    void print()
    {
        for(auto node = head; node !is null; node = node.next) {
            write(format("%s(degree: %s): ", node.name, node.degree));
            for(auto edge = node.edges.head; edge !is null; edge = edge.next) {
                write(format("%s(%s) ", edge.terminus_name, edge.weight));
            }
            write('\n');
        }
    }

    auto copy()
    {
        auto new_list = new VertexList!(VType, EType);

        for(auto node = head; node !is null; node = node.next) {
            new_list.append(node.name);
        }

        return new_list;
    }
}

class EdgeList(VType, EType) {
private:
    size_t length;
    Edge!(VType, EType) *head;
    Edge!(VType, EType) *tail;
public:
    this()
    {
        length = 0;
        head = tail = null;
    }

    void append(VType terminus,
        EType weight,
        Vertex!(VType, EType) *source_vertex,
        Vertex!(VType, EType) *terminus_vertex)
    {
        auto new_node = new Edge!(VType, EType);
        new_node.terminus_name = terminus;
        new_node.weight = weight;
        new_node.source = source_vertex;
        new_node.terminus = terminus_vertex;

        new_node.next = null;
        new_node.prev = tail;

        if(length == 0) {
            head = new_node;
        } else {
            tail.next = new_node;
        }

        tail = new_node;
        length++;
    }

    void remove(VType terminus, EType weight)
    {
        int index = 0;
        for(auto node = head; node !is null; node = node.next, index++) {
            if(node.terminus_name == terminus && node.weight == weight) {
                if(node == head) {
                    popFirst();
                    break;
                } else if(node == tail) {
                    popLast();
                    break;
                }

                node.prev.next = node.next;
                node.next.prev = node.prev;
                length--;
                break;
            }
        }
    }

    auto peek()
    {
        return head;
    }

    void popFirst()
    {
        enforce(length > 0, "The list is empty. Cannot pop first element.");

        head = head.next;
        length--;

        if(head !is null) {
            head.prev = null;
        } else {
            tail = null;
        }
    }

    void popLast()
    {
        enforce(length > 0, "The list is empty. Cannot pop last element.");

        tail = tail.prev;
        length--;

        if(tail !is null) {
            tail.next = null;
        } else {
            head = null;
        }
    }

    bool search(VType terminus, EType weight)
    {
        return getIndex(terminus, weight) != -1;
    }

    auto getIndex(VType terminus, EType weight)
    {
        if(length == 0) {
            return -1;
        }

        int index = 0;
        for(auto node = head; node !is null; node = node.next, index++) {
            if(node.terminus_name == terminus && node.weight == weight) {
                return index;
            }
        }

        // Not found.
        return -1;
    }

    auto size() const @property
    {
        return length;
    }

    bool isEmpty() @property
    {
        return length == 0;
    }
}

class VLRange(VType, EType) {
private:
    size_t currentIndex;
    VertexList!(VType, EType) list;
public:
    this(VertexList!(VType, EType) l)
    {
        list = l.copy();
        currentIndex = 0;
    }

    invariant()
    {
        assert(currentIndex <= list.length);
    }

    bool empty() const
    {
        return list.head is null;
    }

    void popFront()
    {
        list.head = list.head.next;
        currentIndex++;
    }

    auto front() const
    {
        return list.head;
    }
}
