/**
 * This module implements a data structure for a Digraph, as well as
 * the algorithms that were seen in the course.
 *
 * Author: Ivan A. Moreno Soto
 * Date: May 11, 2019
 */
module datastruct.directed.digraph;

/**
 * Container for the attributes of a vertex of a digraph.
 */
struct Vertex(VType, EType) {
    VType name;
    size_t inDegree, outDegree;
    Arc!(VType, EType)[] inArcs;
    Arc!(VType, EType)[] outArcs;
}

/**
 * Container for the attributes of an arc of a digraph.
 */
struct Arc(VType, EType) {
    EType weight;
    // Don't need pointers thanks to the dictionary used by Vertex.
    VType source, terminus, opposite;
}

/**
 * Container for the two attributes needed for Floyd-Warshall's algorithm.
 */
struct FWNode(VType, EType) {
    VType previous;
    EType dist;
}

/**
 * Container for an associative array of FWNodes used by floyd below.
 */
struct FloydDict(VType, EType) {
    FWNode!(VType, EType)[VType][VType] routes;

    /**
     * Outputs to the standard output the contents of the dictionary
     * contained in this struct.
     */
    void print()
    {
        import std.stdio: write;
        import std.string: format;
        import std.algorithm.sorting: sort;

        write('\t');
        foreach(vertex; routes.keys.sort()) {
            write(format("%s\t", vertex));
        }
        write('\n');

        foreach(v; routes.keys.sort()) {
            write(format("%s\t", v));
            foreach(u; routes.keys.sort()) {
                if(routes[v][u].dist != EType.max) {
                    write(format("%s(%s)\t", routes[v][u].previous, routes[v][u].dist));
                } else {
                    write("-(inf)\t");
                }
            }
            write('\n');
        }
    }

    /**
     * Retrieves the path from a vertex to another.
     *
     * Params:
     *      start = Starting vertex
     *      end = Final vertex
     *      length = Length of the shortest path
     *      pathFound = To store whether or not there's a path
     *
     * Returns: List with the shortest path.
     * Throws: Exception when start or end aren't in the dictionary.
     */
    auto retrievePath(VType start, VType end, ref EType length, ref bool pathFound)
    {
        import std.exception: enforce;
        import std.string: format;
        import std.container: DList;
        enforce(start in routes, format("Can't find path for vertex %s because it's not in the digraph.", start));
        enforce(end in routes, format("Can't find path for vertex %s because it's not in the digraph.", end));

        auto path = DList!VType();
        // There's no path.
        if(routes[start][end].dist == EType.max) {
            length = EType.max;
            pathFound = false;
            return path;
        }

        length = routes[start][end].dist;
        path.insertFront(end);

        while(routes[start][end].dist != EType.max && routes[start][end].previous != start) {
            auto next = routes[start][end].previous;
            path.insertFront(next);
            end = next;
        }

        path.insertFront(routes[start][end].previous);
        pathFound = true;

        return path;
    }

    /**
     * Prints every shortest path to the standard output. It also indicates when
     * there isn't one.
     */
    void seeAllPaths()
    {
        import std.stdio: write, writeln;
        import std.string: format;
        import std.algorithm.sorting: sort;

        EType length;
        bool pathFound;

        writeln("List of shortest paths between all vertices.");
        foreach(i; routes.keys.sort()) {
            foreach(j; routes.keys.sort()) {
                auto path = retrievePath(i, j, length, pathFound);
                write(format("%s -> %s: ", i, j));

                if(pathFound) {
                    foreach(v; path[]) {
                        write(format("%s ", v));
                    }
                    write(format("| With length: %s.", length));
                } else {
                    write("No path found.");
                }
                write('\n');
            }
        }
    }
}

/**
 * Class that implements a container for the attributes of a directed graph as
 * well as algorithms for it.
 * VType is the type of the vertices' identifiers. EType is the type for the weights
 * of the arcs.
 */
class Digraph(VType, EType) {
    package Vertex!(VType, EType)[VType] vertices;
    package size_t numVertices, numArcs;

    /**
     * Constructs an empty directed graph.
     */
    this()
    {
        numVertices = numArcs = 0;
    }

    /**
     * Removes every vertex and every arc from the graph.
     */
    public void empty()
    {
        vertices.clear;
        numVertices = numArcs = 0;
    }

    /**
     * Adds a new vertex to the graph with the given identifier. If the identifier
     * is already associated with a vertex, the function returns.
     *
     * Params:
     *      name = Identifier for the new vertex
     */
    public void addVertex(VType name)
    {
        if((name in vertices) !is null) {
            return;
        }

        vertices[name] = Vertex!(VType, EType)(name, 0, 0, [], []);
        numVertices++;
    }

    /**
     * Removes the given vertex from the graph.
     *
     * Params:
     *      name = Identifier for the vertex that needs to be removed
     *
     * Throws: Exception if the identifier doesn't exist in the graph.
     */
    public void removeVertex(VType name)
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(name in vertices, format("Tried to erase vertex %s but it isn't on the digraph.", name));

        disconnectVertex(name);
        vertices.remove(name);
        numVertices--;
    }

    /**
     * Removes every arc that touches the given vertex, without removing it.
     *
     * Params:
     *      name = Identifier of the vertex to be disconnected
     *
     * Throws: Exception if the identifier doesn't exist in the digraph.
     */
    public void disconnectVertex(VType name)
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(name in vertices, format("Tried to disconnect vertex %s but it isn't on the digraph.", name));

        foreach(arc; vertices[name].outArcs) {
            removeArc(arc.source, arc.terminus, arc.weight);
        }

        foreach(arc; vertices[name].inArcs) {
            removeArc(arc.source, arc.terminus, arc.weight);
        }
    }

    /**
     * Adds an arc between two vertices with weight 1. If the arc is a loop,
     * only one new Arc instance is created.
     *
     * Params:
     *      source = Identifier for the source vertex
     *     terminus = Identifier for the terminus vertex
     *
     * Throws: Exception if any of the identifiers don't exist in the digraph.
     */
    public void addArc(VType source, VType terminus)
    {
        addArc(source, terminus, 1);
    }

    /**
     * Adds an arc between two vertices with the given weight.
     *
     * Params:
     *      source = Identifier for the source vertex
     *      terminus = Identifier for the terminus vertex
     *      weight = Weight of the new arc
     *
     * Throws: Exception if any of the identifiers don't exist in the digraph.
     */
    public void addArc(VType source, VType terminus, EType weight)
    {
        import std.exception: enforce;
        enforce(source in vertices, "Tried to add an arc from an inexistent vertex.");
        enforce(terminus in vertices, "Tried to add an arc to an inexistent vertex.");

        vertices[source].outArcs ~= Arc!(VType, EType)(weight, source, terminus, terminus);
        vertices[source].outDegree++;

        vertices[terminus].inArcs ~= Arc!(VType, EType)(weight, source, terminus, source);
        vertices[terminus].inDegree++;

        numArcs++;
    }

    /**
     * Removes an arc between the given vertices with weight 1.
     *
     * Params:
     *      source = Identifier for the source vertex
     *      terminus = Identifier for the terminus vertex
     *
     * Throws: Exception if any of the identifiers don't exist in the digraph or the
     * specified arc doesn't exist.
     */
    public void removeArc(VType source, VType terminus)
    {
        removeArc(source, terminus, 1);
    }

    /**
     * Removes an arc between the given vertices with the given weight.
     *
     * Params:
     *      source = Identifier for the source vertex
     *      terminus = Identifier for the terminus vertex
     *      weight = Weight of the arc
     *
     * Throws: Exception if any of the identifiers don't exist in the digraph or the
     * specified arc doesn't exist.
     */
    public void removeArc(VType source, VType terminus, EType weight)
    {
        import std.exception: enforce;
        import std.algorithm: countUntil;
        import std.algorithm.mutation: remove;

        enforce(source in vertices, "Tried to remove an arc from an inexistent vertex.");
        enforce(terminus in vertices, "Tried to remove an arc to an inexistent vertex.");

        auto index = countUntil(vertices[source].outArcs, Arc!(VType, EType)(weight, source, terminus, terminus));
        enforce(index > -1, "Tried to remove an inexistent arc.");
        vertices[source].outArcs = remove(vertices[source].outArcs, index);
        vertices[source].outDegree--;

        index = countUntil(vertices[terminus].inArcs, Arc!(VType, EType)(weight, source, terminus, source));
        vertices[terminus].inArcs = remove(vertices[terminus].inArcs, index);
        vertices[terminus].inDegree--;

        numArcs--;
    }

    /**
     * Checks if an arc is on the outArcs of a certain vertex.
     *
     * Params:
     *      source = Identifier for the source
     *      terminus = Identifier for the terminus
     *
     * Returns: true if the arc is found, false otherwise.
     * Throws: Exception if the source it's not in the digraph.
     */
    public auto doesVertexHaveArc(VType source, VType terminus)
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(source in vertices, format("Cannot look for an arc in an inexistent vertex: %s.", source));

        foreach(arc; vertices[source].outArcs) {
            if(arc.terminus == terminus) {
                return true;
            }
        }

        return false;
    }

    /**
     * Checks if a specific arc is on the outArcs of a certain vertex.
     *
     * Params:
     *      source = Identifier for the source
     *      terminus = Identifier for the terminus
     *      weight = Weight of the arc
     *
     * Returns: true if the arc is found, false otherwise.
     * Throws: Exception if the source it's not in the digraph.
     */
    public auto doesVertexHaveArc(VType source, VType terminus, EType weight)
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(source in vertices, format("Cannot look for an arc in an inexistent vertex: %s.", source));

        foreach(arc; vertices[source].outArcs) {
            if(arc.terminus == terminus && arc.weight == weight) {
                return true;
            }
        }

        return false;
    }

    /**
     * Copies the contents of the digraph to a new Digraph instance.
     *
     * Returns: The new Digraph object.
     */
    auto copy()
    {
        auto digraphCopy = new Digraph!(VType, EType);
        digraphCopy.vertices = vertices.dup;
        digraphCopy.numVertices = numVertices;
        digraphCopy.numArcs = numArcs;

        return digraphCopy;
    }

    /**
     * Prints the contents of the digraph to the standard output.
     */
    public void print() const
    {
        import std.stdio: write, writeln;
        import std.string: format;

        foreach(vertex; vertices.byValue()) {
            write(format("%s(+degree: %s, -degree: %s): ", vertex.name, vertex.outDegree, vertex.inDegree));
            foreach(arc; vertex.outArcs) {
                write(format("%s(w: %s) ", arc.terminus, arc.weight));
            }
            write('\n');
        }
        writeln(format("The digraph has %s vertice(s) and %s arc(s).", numVertices, numArcs));
    }

    /**
     * Takes a Networkx JSON file and creates a Digraph from it.
     *
     * Params:
     *      filePath = Path to the JSON file
     *
     * Returns: Digraph instance with the information contained in filePath.
     */
    public auto loadFromNxJSON(string filePath)
    {
        import std.json;
        import std.stdio: File;

        // Reading and parsing the input graph.
        auto outputFile = File(filePath, "r");
        auto fileContents = outputFile.readln();
        JSONValue jsonGraph = parseJSON(fileContents);

        // Creating the new graph from the JSON.
        auto graph = new Digraph!(VType, EType)();
        foreach(vertex; jsonGraph["nodes"].array) {
            graph.addVertex(vertex["id"].str);
        }
        foreach(edge; jsonGraph["links"].array) {
            graph.addArc(edge["source"].str, edge["target"].str, edge["weight"].integer);
        }

        return graph;
    }

    /**
     * Saves the digraph in a text file with a format useful
     * for Networkx (in Python).
     * Text file format:
     *      digraph header -> digraph
     *      vertices header -> vertex
     *      vertices -> name of every vertex in the digraph
     *      arcs header -> edges
     *      arcs -> source terminus weight
     *      extra information -> key value
     *      footer -> end
     *
     * Params:
     *      id = ID for the text file
     *      additionalInfo = Additional information accompanying the digraph
     */
    public void saveToFile(string id, string[] additionalInfo = null)
    {
        import std.stdio: File;
        import std.string: format;

        string filePath = format("../../data/%s-final.txt", id);
        auto outputFile = File(filePath, "w");
        // Header.
        outputFile.writeln("digraph");
        // Vertices.
        outputFile.writeln("vertex");
        foreach(vertex; vertices.byKey) {
            outputFile.writeln(format("%s %s", vertex, vertex));
        }
        // Arcs.
        outputFile.writeln("edges");
        foreach(vertex; vertices.byKey) {
            foreach(arc; vertices[vertex].outArcs) {
                outputFile.writeln(format("%s %s %s", arc.source, arc.terminus, arc.weight));
            }
        }

        if(additionalInfo !is null) {
            outputFile.writeln("extra");
            foreach(extra; additionalInfo) {
                outputFile.writeln(extra);
            }
        }
        outputFile.writeln("end");
    }

    /**
     * Saves many digraphs in a text file with a format useful
     * for Networkx (in Python).
     * Text file format:
     *      digraph header -> digraph
     *      vertices header -> vertex
     *      vertices -> name of every vertex in the digraph
     *      arcs header -> edges
     *      arcs -> source terminus weight
     *      footer -> end
     *
     * Params:
     *      id = ID for the text file
     *      trees = Array of digraphs to be saved
     */
    public void saveFloydToFile(string id, Digraph!(VType, EType)[] trees)
    {
        import std.stdio: File;
        import std.string: format;

        string filePath = format("../../data/%s-final.txt", id);
        auto outputFile = File(filePath, "w");
        // Header.
        outputFile.writeln("digraph");

        // Vertices.
        string subfix = "";
        outputFile.writeln("vertex");
        foreach(digraph; trees) {
            foreach(vertex; digraph.vertices.byKey) {
                outputFile.writeln(format("%s%s %s", vertex, subfix, vertex));
            }

            subfix = format("%s'", subfix);
        }

        // Arcs.
        subfix = "";
        outputFile.writeln("edges");
        foreach(digraph; trees) {
            foreach(vertex; digraph.vertices.byKey) {
                foreach(arc; digraph.vertices[vertex].outArcs) {
                    outputFile.writeln(format("%s%s %s%s %s", arc.source, subfix, arc.terminus, subfix, arc.weight));
                }
            }

            subfix = format("%s'", subfix);
        }

        outputFile.writeln("end");
    }

    /**
     * Returns true if name exists in the digraph, false otherwise.
     */
    public bool isVertexOnDigraph(VType name) const
    {
        return (name in vertices) !is null;
    }

    /**
     * Returns the degree of the given vertex.
     *
     * Params:
     *      name = Identifier of the vertex
     *
     * Returns: Integer with the degree of the vertex.
     * Throws: Exception if the identifier doesn't exist in the digraph.
     */
    public auto getVertexDegree(VType name) const
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(name in vertices, format("Tried to get the degree for vertex %s that isn't on the digraph.", name));

        return vertices[name].outDegree + vertices[name].inDegree;
    }

    /**
     * Returns an arc between the two given vertices.
     *
     * Params:
     *      source = Source of the arc
     *      terminus = Terminus of the arc
     *
     * Returns: An Arc instance.
     */
    private auto searchArcOut(VType source, VType terminus)
    {
        foreach(arc; vertices[source].outArcs) {
            if(arc.terminus == terminus) {
                return arc;
            }
        }

        return Arc!(VType, EType)(0, source, terminus, terminus);
    }

    /**
     * Returns the current number of vertices in the digraph.
     */
    public auto numberVertices() const @property
    {
        return numVertices;
    }

    /**
     * Returns the current number of arcs in the digraph.
     */
    public auto numberArcs() const @property
    {
        return numArcs;
    }

    /**
     * Returns true if the digraph is empty, false otherwise.
     */
    public bool isEmpty() const @property
    {
        return numVertices == 0;
    }

    /**
     * Searches for a negative cycle in a digraph.
     *
     * Params:
     *      end = Vertex where the cycle ends, or where the search begins
     *      start = Start of the cycle, or where the search ends
     *      previous = AA that stores the previous vertex in another's shortest path
     *      cycleFound = Boolean that indicates if a negative cycle was found
     *
     * Returns: A new Digraph instance with the cycle found.
     */
    private auto searchNegativeCycles(VType end, VType start, ref VType[VType] previous, ref bool cycleFound)
    {
        auto cycle = new Digraph!(VType, EType)();
        cycle.addVertex(end);
        cycleFound = false;

        for(auto vertex = end; !cycleFound; vertex = previous[vertex]) {
            // If we found a negative cycle.
            if(vertex == start) {
                cycleFound = true;
                continue;
            }
            cycle.addVertex(previous[vertex]);
            // If we can add another arc.
            if(vertex != previous[vertex]) {
                cycle.addArc(previous[vertex], vertex, vertices[vertex].inArcs[0].weight);
            }
            // If we can't keep searching.
            if(vertex == previous[vertex]) {
                break;
            }
        }

        return cycle;
    }

    /**
     * Updates the shortest paths subtree of a given root.
     *
     * Params:
     *      root = Root for the subtree of shortest paths
     *      delta = Amount that the shortest paths subtree will decrease
     *      shortestPaths = AA with the shortest paths tree
     */
    private void updateShortestPathTree(VType root, EType delta, ref EType[VType] shortestPaths)
    {
        foreach(arc; vertices[root].outArcs) {
            shortestPaths[arc.terminus] -= delta;
            updateShortestPathTree(arc.terminus, delta, shortestPaths);
        }
    }

    /**
     * Computes a shortest paths tree using Dijkstra's algorithm.
     *
     * Params:
     *      start = Vertex where the routes start
     *      shortestPaths = AA to store the shortest path's length to every vertex
     *      previous = AA to store the previous vertex in another's shortest path
     *
     * Returns: Shortest paths tree as a new Digraph instance.
     * Throws: Exception if start is not in the digraph.
     */
    private auto dijkstra(VType start, ref EType[VType] shortestPaths, ref VType[VType] previous)
    {
        import std.exception: enforce;
        import std.string: format;
        import std.algorithm: canFind;
        import datastruct.heap;
        enforce(start in vertices, format("Vertex %s isn't on this digraph.", start));

        enum {infinity = 0, temporary = 1, definitive = 2}
        auto tree = new Digraph!(VType, EType)();
        auto touchedVertices = new Heap!(Vertex!(VType, EType), EType)(numVertices);

        // Defining auxiliary dictionaries to store attributes specific to this algorithm.
        EType[VType] prevArcWeight;
        int[VType] states;
        foreach(vertex; vertices.byKey()) {
            shortestPaths[vertex] = EType.max;
            prevArcWeight[vertex] = EType.max;
            previous[vertex] = vertex;
            states[vertex] = infinity;
        }

        // Adding the initial vertex.
        shortestPaths[start] = 0;
        prevArcWeight[start] = 0;
        states[start] = temporary;
        touchedVertices.insert(vertices[start], 0);

        // Searching for new shortest paths.
        while(!touchedVertices.isEmpty) {
            auto vertex = touchedVertices.deleteTop();
            states[vertex.name] = definitive;
            tree.addVertex(vertex.name);

            // Finishing early.
            if(!canFind(states.values, infinity) && !canFind(states.values, temporary)) {
                break;
            }

            foreach(arc; vertex.outArcs) {
                auto terminus = arc.terminus;
                if(states[terminus] == infinity) {
                    // Changing the terminus's attributes.
                    states[terminus] = temporary;
                    previous[terminus] = vertex.name;
                    shortestPaths[terminus] = shortestPaths[vertex.name] + arc.weight;
                    touchedVertices.insert(vertices[terminus], shortestPaths[terminus]);
                    // Updating the shortest paths tree.
                    tree.addVertex(terminus);
                    tree.addArc(vertex.name, terminus, arc.weight);
                    prevArcWeight[terminus] = arc.weight;
                } else if(states[terminus] == temporary && shortestPaths[vertex.name] + arc.weight < shortestPaths[terminus]) {
                    // Updating the shortest paths tree.
                    tree.removeArc(previous[terminus], terminus, prevArcWeight[terminus]);
                    tree.addArc(vertex.name, terminus, arc.weight);
                    prevArcWeight[terminus] = arc.weight;
                    // Updating the attributes.
                    previous[terminus] = vertex.name;
                    shortestPaths[terminus] = shortestPaths[vertex.name] + arc.weight;
                    touchedVertices.insert(vertices[terminus], shortestPaths[terminus]);
                }
            }
        }

        return tree;
    }

    /**
     * Uses a generalization of Dijkstra's algorithm to find a shortest paths tree
     * in a digraph with or without negative weights.
     *
     * Params:
     *      start = Identifier for the starting vertex
     *      cycleFound = Indicates whether the returned digraph is a negative cycle or a tree
     *      shortestPaths = AA to store the shortest path's length to every vertex
     *      previous = AA to store the previous vertex in another's shortest path
     *
     * Returns: Shortest paths tree as a new Digraph instance, or if a negative cycle is found,
     * a Digraph instance that has the vertices and arcs that make it.
     * Throws: Exception if start is not in the digraph.
     */
    public auto dijkstra(VType start, ref bool cycleFound, ref EType[VType] shortestPaths, ref VType[VType] previous)
    {
        import std.exception: enforce;
        import std.string: format;
        import datastruct.heap;
        enforce(start in vertices, format("Vertex %s isn't on this digraph.", start));

        //EType[VType] shortestPaths;
        //VType[VType] previous;
        auto tree = dijkstra(start, shortestPaths, previous);

        // Now, we look for all the arcs that aren't included in the initial solution.
        auto missingArcs = new Heap!(Arc!(VType, EType), EType)(numArcs);
        foreach(vertex; vertices.byValue) {
            foreach(arc; vertex.outArcs) {
                if(arc.source in tree.vertices && !tree.doesVertexHaveArc(arc.source, arc.terminus, arc.weight)) {
                    missingArcs.insert(arc, arc.weight);
                }
            }
        }

        if(missingArcs.isEmpty) {
            return tree;
        }

        for(auto arc = missingArcs.deleteTop(); !missingArcs.isEmpty; arc = missingArcs.deleteTop()) {
            if(shortestPaths[arc.source] + arc.weight < shortestPaths[arc.terminus]) {
                auto cycle = tree.searchNegativeCycles(arc.source, arc.terminus, previous, cycleFound);
                if(cycleFound) {
                    cycle.addArc(arc.source, arc.terminus, arc.weight);
                    return cycle;
                }

                // Adding to the heap the arc that we're going to remove.
                auto oldArc = tree.vertices[arc.terminus].inArcs[0];
                missingArcs.insert(oldArc, oldArc.weight);

                // Swapping the arcs.
                tree.removeArc(oldArc.source, oldArc.terminus, oldArc.weight);
                tree.addArc(arc.source, arc.terminus, arc.weight);

                // Updating the shortest paths tree.
                auto oldMinimumWeight = shortestPaths[arc.terminus];
                shortestPaths[arc.terminus] = shortestPaths[arc.source] + arc.weight;
                previous[arc.terminus] = arc.source;
                tree.updateShortestPathTree(arc.terminus, oldMinimumWeight - shortestPaths[arc.terminus], shortestPaths);

                // Now, we look for all the arcs that aren't included in the initial solution.
                foreach(vertex; vertices.byValue) {
                    foreach(arc_; vertex.outArcs) {
                        if(arc_.source in tree.vertices && !tree.doesVertexHaveArc(arc_.source, arc_.terminus, arc_.weight)) {
                            missingArcs.insert(arc_, arc_.weight);
                        }
                    }
                }
            }
        }

        return tree;
    }

    /**
     * Finds a shortest path between every pair of vertices using Floyd-Warshall's
     * algorithm.
     *
     * Returns: Struct with an associative array with the previous vertex and shortest path length for every vertex.
     * Throws: Exception when a negative cycle is found.
     */
    public auto floyd()
    {
        import std.exception: enforce;
        import std.string: format;

        enum infinity = EType.max;
        auto routes = FloydDict!(VType, EType)();

        // Creating the initial adjacency matrix.
        foreach(v; vertices.byKey) {
            foreach(u; vertices.byKey) {
                if(v == u) {
                    routes.routes[v][u] = FWNode!(VType, EType)(v, 0);
                } else if(doesVertexHaveArc(v, u)) {
                    routes.routes[v][u] = FWNode!(VType, EType)(v, searchArcOut(v, u).weight);
                } else {
                   routes.routes[v][u] = FWNode!(VType, EType)(v, infinity);
                }
            }
        }

        // Updating the shortest paths between each vertex.
        foreach(k; vertices.byKey) {
            foreach(i; vertices.byKey) {
                if(routes.routes[i][k].dist == infinity || i == k) continue;

                foreach(j; vertices.byKey) {
                    if(routes.routes[k][j].dist == infinity || j == k) continue;

                    auto d = routes.routes[i][k].dist + routes.routes[k][j].dist;
                    if(d < routes.routes[i][j].dist) {
                        routes.routes[i][j].dist = d;
                        routes.routes[i][j].previous = routes.routes[k][j].previous;

                        // Looking for a negative cycle.
                        if(i == j) {
                            bool pathFound;
                            EType length;
                            auto cycle = routes.retrievePath(i, j, length, pathFound);
                            enforce(i != j, format("Negative cycle found: %s, with length %s.", cycle, length));
                        }
                    }
                }
            }
        }

        return routes;
    }

    /**
     * Takes a FloydDict and returns an array with all the shortest path trees
     * in it.
     *
     * Params:
     *      dict = FloydDict from floyd
     *
     * Returns: Array of Digraph instances.
     */
    public auto getTreesFromDict(FloydDict!(VType, EType) dict)
    {
        Digraph!(VType, EType)[] trees;
        int currentTree = 0;

        foreach(v; vertices.byKey) {
            trees ~= new Digraph!(VType, EType)();
            trees[currentTree].addVertex(v);

            foreach(u; vertices.byKey) {
                if(v != u && dict.routes[v][u].dist != EType.max) {
                    trees[currentTree].addVertex(dict.routes[v][u].previous);
                    trees[currentTree].addVertex(u);

                    auto arc = searchArcOut(dict.routes[v][u].previous, u);
                    trees[currentTree].addArc(arc.source, arc.terminus, arc.weight);
                }
            }

            currentTree++;
        }

        return trees;
    }
}
