module datastruct.undirected.graph;

struct Vertex(VType, EType) {
    VType name;
    size_t degree;
    Edge!(VType, EType)[] edges;
}

struct Edge(VType, EType) {
    EType weight;
    VType source, terminus;
    //Vertex!(VType, EType)* source, terminus;
}

class Graph(VType, EType) {
    private Vertex!(VType, EType)[VType] vertices;
    private size_t numVertices, numEdges;

    this()
    {
        numVertices = numEdges = 0;
    }

    public void empty()
    {
        vertices.clear;
        numVertices = numEdges = 0;
    }

    public void addVertex(VType name)
    {
        import std.stdio: writeln;

        writeln("qweruttioutio");

        if((name in vertices) !is null) {
            return;
        }

        writeln("uttioutio");

        vertices[name] = Vertex!(VType, EType)(name, 0, []);
        numVertices++;
    }

    public void removeVertex(VType name)
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(name in vertices, format("Tried to erase vertex %s but it isn't on the graph.", name));

        disconnectVertex(name);
        vertices.remove(name);
        numVertices--;
    }

    public void addEdge(VType source, VType terminus)
    {
        addEdge(source, terminus, 1);
    }

    public void addEdge(VType source, VType terminus, EType weight)
    {
        import std.exception: enforce;
        enforce(source in vertices, "Tried to add an edge from an inexistent vertex.");
        enforce(terminus in vertices, "Tried to add an edge to an inexistent vertex.");

        vertices[source].edges[ vertices[source].edges.length ] = Edge!(VType, EType)(weight, source, terminus);
        vertices[source].degree++;

        if(source != terminus) {
            vertices[terminus].edges[ vertices[terminus].edges.length ] = Edge!(VType, EType)(weight, terminus, source);
            vertices[terminus].degree++;
        } else {
            vertices[source].degree++;
        }

        numEdges++;
    }

    public void removeEdge(VType source, VType terminus)
    {
        removeEdge(source, terminus, 1);
    }

    public void removeEdge(VType source, VType terminus, EType weight)
    {
        import std.exception: enforce;
        import std.algorithm: countUntil;
        import std.algorithm.mutation: remove;

        enforce(source in vertices, "Tried to remove an edge from an inexistent vertex.");
        enforce(terminus in vertices, "Tried to remove an edge to an inexistent vertex.");

        auto index = countUntil(vertices[source].edges, Edge!(VType, EType)(weight, source, terminus));
        vertices[source].edges = remove(vertices[source].edges, index);
        vertices[source].degree--;

        if(source != terminus) {
            index = countUntil(vertices[source].edges, Edge!(VType, EType)(weight, terminus, source));
            vertices[terminus].edges = remove(vertices[terminus].edges, index);
            vertices[terminus].degree--;
        } else {
            vertices[source].degree--;
        }

        numEdges--;
    }

    public void disconnectVertex(VType name)
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(name in vertices, format("Tried to disconnect vertex %s but it isn't on the graph.", name));

        foreach(edge; vertices[name].edges) {
            removeEdge(edge.source, edge.terminus, edge.weight);
        }
    }

    public bool isVertexOnGraph(VType name)
    {
        return (name in vertices) !is null;
    }

    public void print()
    {
        import std.stdio: write, writeln;
        import std.string: format;

        foreach(vertex; vertices.byValue()) {
            write(format("%s(degree: %s): ", vertex.name, vertex.degree));
            foreach(edge; vertex.edges) {
                write(format("%s(w: %s)", edge.terminus, edge.weight));
            }
        }
        writeln(format("The graph has %s vertice(s) and %s edge(s).", numVertices, numEdges));
    }

    /*
    auto copy()
    {
        auto graph_copy = new Graph!(VType, EType);

        for(auto vertex = vertices.peek(); vertex !is null; vertex = vertex.next) {
            graph_copy.addVertex(vertex.name);
        }

        auto new_vertex = graph_copy.vertices.peek();
        for(auto orig_vertex = vertices.peek(); orig_vertex !is null; orig_vertex = orig_vertex.next, new_vertex = new_vertex.next) {
            // Passing all the vertex's attributes over.
            new_vertex.degree = orig_vertex.degree;

            // Adding every edge directly to the current new_vertex's edge list.
            for(auto edge = orig_vertex.edges.peek(); edge !is null; edge = edge.next) {
                new_vertex.edges.append(edge.terminus_name, edge.weight, new_vertex, graph_copy.vertices.peek(edge.terminus_name));
            }
        }
        graph_copy.num_edges = num_edges;

        return graph_copy;
    }
    */

    public auto getVertexDegree(VType name)
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(name in vertices, format("Tried to get the degree for vertex %s that isn't on the graph.", name));

        return vertices[name].degree;
    }

    public auto numberVertices() const @property
    {
        return numVertices;
    }

    public auto numberEdges() const @property
    {
        return numEdges;
    }

    public bool isEmpty() const @property
    {
        return numVertices == 0;
    }
}
