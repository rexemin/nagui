module datastruct.undirected.graph;

import std.stdio;
import std.string: format;
import std.exception: enforce;
import datastruct.undirected.glist;

class Graph(VType, EType) {
private:
    VertexList!(VType, EType) vertices;
    size_t num_vertices;
    size_t num_edges;
public:
    this()
    {
        num_vertices = num_edges = 0;
        vertices = new VertexList!(VType, EType);
    }

    void empty()
    {
        destroy(vertices);
        vertices = new VertexList!(VType, EType);
        num_vertices = num_edges = 0;
    }

    void addVertex(VType name)
    {
        if(vertices.search(name)) {
            return;
        }

        vertices.append(name);
        num_vertices++;
    }

    void removeVertex(VType name)
    {
        enforce(vertices.search(name), format("Tried to erase vertex %s but it isn't on the graph.", name));

        disconnectVertex(name);
        vertices.remove(name);
        num_vertices--;
    }

    void addEdge(VType source, VType terminus)
    {
        addEdge(source, terminus, 1);
    }

    void addEdge(VType source, VType terminus, EType weight)
    {
        auto source_vertex = vertices.peek(source);
        auto terminus_vertex = vertices.peek(terminus);

        enforce(source_vertex !is null, "Tried to add an edge from an inexistent vertex.");
        enforce(terminus_vertex !is null, "Tried to add an edge to an inexistent vertex.");

        source_vertex.edges.append(terminus, weight, source_vertex, terminus_vertex);
        source_vertex.degree++;

        if(source_vertex != terminus_vertex) {
            terminus_vertex.edges.append(source, weight, terminus_vertex, source_vertex);
            terminus_vertex.degree++;
        } else {
            source_vertex.degree++;
        }

        num_edges++;
    }

    void removeEdge(VType source, VType terminus)
    {
        removeEdge(source, terminus, 1);
    }

    void removeEdge(VType source, VType terminus, EType weight)
    {
        auto source_vertex = vertices.peek(source);
        auto terminus_vertex = vertices.peek(terminus);

        enforce(source_vertex !is null, "Tried to remove an edge from an inexistent vertex.");
        enforce(terminus_vertex !is null, "Tried to remove an edge to an inexistent vertex.");

        source_vertex.edges.remove(terminus, weight);
        source_vertex.degree--;

        if(source_vertex != terminus_vertex) {
            terminus_vertex.edges.remove(source, weight);
            terminus_vertex.degree--;
        } else {
            source_vertex.degree--;
        }

        num_edges--;
    }

    void disconnectVertex(VType name)
    {
        enforce(vertices.search(name), format("Tried to disconnect vertex %s but it isn't on the graph.", name));

        auto vertex = vertices.peek(name);
        for(auto edge = vertex.edges.peek(); edge !is null; edge = vertex.edges.peek()) {
            removeEdge(vertex.name, edge.terminus.name, edge.weight);
        }
    }

    bool isVertexOnGraph(VType name)
    {
        return vertices.search(name);
    }

    void print()
    {
        vertices.print();
        writeln(format("The graph has %s vertice(s) and %s edge(s).", num_vertices, num_edges));
    }

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

    auto getVertexDegree(VType name)
    {
        enforce(vertices.search(name), format("Tried to get the degree for vertex %s that isn't on the graph.", name));
        return vertices.peek(name).degree;
    }

    auto numVertices() const @property
    {
        return num_vertices;
    }

    auto numEdges() const @property
    {
        return num_edges;
    }

    bool isEmpty() const @property
    {
        return num_vertices == 0;
    }
}
