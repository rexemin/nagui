/**
 * This module implements the data structures and the algorithms for graphs seen
 * during the course.
 *
 * Author: Ivan A. Moreno Soto
 * Date: May 12, 2019
 */
module datastruct.undirected.graph;

/**
 * Container for the attributes of a vertex of a graph.
 */
struct Vertex(VType, EType) {
    VType name;
    size_t degree, level;
    Edge!(VType, EType)[] edges;
}

/**
 * Container for the attributes of an edge of a graph.
 */
struct Edge(VType, EType) {
    EType weight;
    // Don't need pointers thanks to the dictionary used by Vertex.
    VType source, terminus;
}

/**
 * Class that implements a container for the attributes of an undirected graph as
 * well as algorithms for it.
 * VType is the type of the vertices' identifiers. EType is the type for the weights
 * of the edges.
 */
class Graph(VType, EType) {
    private Vertex!(VType, EType)[VType] vertices;
    private size_t numVertices, numEdges;

    /**
     * Constructs an empty undirected graph.
     */
    this()
    {
        numVertices = numEdges = 0;
    }

    /**
     * Removes every vertex and every edge from the graph.
     */
    public void empty()
    {
        vertices.clear;
        numVertices = numEdges = 0;
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

        vertices[name] = Vertex!(VType, EType)(name, 0, 0, []);
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
        enforce(name in vertices, format("Tried to erase vertex %s but it isn't on the graph.", name));

        disconnectVertex(name);
        vertices.remove(name);
        numVertices--;
    }

    /**
     * Adds an edge between two vertices with weight 1. If the edge is a loop,
     * only one new Edge instance is created.
     *
     * Params:
     *      source = Identifier for the source vertex
     *     terminus = Identifier for the terminus vertex
     *
     * Throws: Exception if any of the identifiers don't exist in the graph.
     */
    public void addEdge(VType source, VType terminus)
    {
        addEdge(source, terminus, 1);
    }

    /**
     * Adds an edge between two vertices with the given weight. If the edge is a loop,
     * only one new Edge instance is created.
     *
     * Params:
     *      source = Identifier for the source vertex
     *      terminus = Identifier for the terminus vertex
     *      weight = Weight of the new edge
     *
     * Throws: Exception if any of the identifiers don't exist in the graph.
     */
    public void addEdge(VType source, VType terminus, EType weight)
    {
        import std.exception: enforce;
        enforce(source in vertices, "Tried to add an edge from an inexistent vertex.");
        enforce(terminus in vertices, "Tried to add an edge to an inexistent vertex.");

        vertices[source].edges ~= Edge!(VType, EType)(weight, source, terminus);
        vertices[source].degree++;

        if(source != terminus) {
            vertices[terminus].edges ~= Edge!(VType, EType)(weight, terminus, source);
            vertices[terminus].degree++;
        } else {
            vertices[source].degree++;
        }

        numEdges++;
    }

    /**
     * Removes an edge between the given vertices with weight 1.
     *
     * Params:
     *      source = Identifier for the source vertex
     *      terminus = Identifier for the terminus vertex
     *
     * Throws: Exception if any of the identifiers don't exist in the graph or the
     * specified edge doesn't exist.
     */
    public void removeEdge(VType source, VType terminus)
    {
        removeEdge(source, terminus, 1);
    }

    /**
     * Removes an edge between the given vertices with the given weight.
     *
     * Params:
     *      source = Identifier for the source vertex
     *      terminus = Identifier for the terminus vertex
     *      weight = Weight of the edge
     *
     * Throws: Exception if any of the identifiers don't exist in the graph or the
     * specified edge doesn't exist.
     */
    public void removeEdge(VType source, VType terminus, EType weight)
    {
        import std.exception: enforce;
        import std.algorithm: countUntil;
        import std.algorithm.mutation: remove;

        enforce(source in vertices, "Tried to remove an edge from an inexistent vertex.");
        enforce(terminus in vertices, "Tried to remove an edge to an inexistent vertex.");

        auto index = countUntil(vertices[source].edges, Edge!(VType, EType)(weight, source, terminus));
        enforce(index > -1, "Tried to remove an inexistent edge.");
        vertices[source].edges = remove(vertices[source].edges, index);
        vertices[source].degree--;

        if(source != terminus) {
            index = countUntil(vertices[terminus].edges, Edge!(VType, EType)(weight, terminus, source));
            vertices[terminus].edges = remove(vertices[terminus].edges, index);
            vertices[terminus].degree--;
        } else {
            vertices[source].degree--;
        }

        numEdges--;
    }

    /**
     * Removes every edge that touches the given vertex, without removing it.
     *
     * Params:
     *      name = Identifier of the vertex to be disconnected
     *
     * Throws: Exception if the identifier doesn't exist in the graph.
     */
    public void disconnectVertex(VType name)
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(name in vertices, format("Tried to disconnect vertex %s but it isn't on the graph.", name));

        foreach(edge; vertices[name].edges) {
            removeEdge(edge.source, edge.terminus, edge.weight);
        }
    }

    /**
     * Copies the contents of the graph to a new Graph instance.
     *
     * Returns: The new Graph object.
     */
    auto copy()
    {
        auto graphCopy = new Graph!(VType, EType);
        graphCopy.vertices = vertices.dup;
        graphCopy.numVertices = numVertices;
        graphCopy.numEdges = numEdges;

        return graphCopy;
    }

    /**
     * Prints the contents of the graph to the standard output.
     */
    public void print() const
    {
        import std.stdio: write, writeln;
        import std.string: format;

        foreach(vertex; vertices.byValue()) {
            write(format("%s(degree: %s, level: %s): ", vertex.name, vertex.degree, vertex.level));
            foreach(edge; vertex.edges) {
                write(format("%s(w: %s) ", edge.terminus, edge.weight));
            }
            write('\n');
        }
        writeln(format("The graph has %s vertice(s) and %s edge(s).", numVertices, numEdges));
    }

    /**
     * Takes a Networkx JSON file and creates a Graph from it.
     *
     * Params:
     *      filePath = Path to the JSON file
     *
     * Returns: Graph instance with the information contained in filePath.
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
        auto graph = new Graph!(VType, EType)();
        foreach(vertex; jsonGraph["nodes"].array) {
            graph.addVertex(vertex["id"].str);
        }
        foreach(edge; jsonGraph["links"].array) {
            graph.addEdge(edge["source"].str, edge["target"].str, edge["weight"].integer);
        }

        return graph;
    }

    /**
     * Saves the graph in a text file with a format useful
     * for Networkx (in Python).
     * Text file format:
     *      graph header -> graph
     *      vertices header -> vertex
     *      vertices -> name of every vertex in the digraph
     *      arcs header -> edges
     *      arcs -> source terminus weight
     *      extra information -> key value
     *      footer -> end
     *
     * Params:
     *      id = ID for the text file
     */
    public void saveToFile(string id, string[] additionalInfo = null)
    {
        import std.stdio: File;
        import std.string: format;

        string filePath = format("../../data/%s-final.txt", id);
        auto outputFile = File(filePath, "w");
        // Header.
        outputFile.writeln("graph");
        // Vertices.
        outputFile.writeln("vertex");
        foreach(vertex; vertices.byKey) {
            outputFile.writeln(vertex);
        }
        // Arcs.
        outputFile.writeln("edges");
        foreach(vertex; vertices.byKey) {
            foreach(arc; vertices[vertex].edges) {
                outputFile.writeln(format("%s %s %s", arc.source, arc.terminus, arc.weight));
            }
        }
        // Extra information.
        if(additionalInfo !is null) {
            outputFile.writeln("extra");
            foreach(extra; additionalInfo) {
                outputFile.writeln(extra);
            }
        }

        outputFile.writeln("end");
    }

    /**
     * Returns true if name exists in the graph, false otherwise.
     */
    public bool isVertexOnGraph(VType name) const
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
     * Throws: Exception if the identifier doesn't exist in the graph.
     */
    public auto getVertexDegree(VType name) const
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(name in vertices, format("Tried to get the degree for vertex %s that isn't on the graph.", name));

        return vertices[name].degree;
    }

    /**
     * Returns the current number of vertices in the graph.
     */
    public auto numberVertices() const @property
    {
        return numVertices;
    }

    /**
     * Returns the current number of edges in the graph.
     */
    public auto numberEdges() const @property
    {
        return numEdges;
    }

    /**
     * Returns true if the graph is empty, false otherwise.
     */
    public bool isEmpty() const @property
    {
        return numVertices == 0;
    }

    /**
     * Returns true if every vertex on the graph has an even degree,
     * false otherwise. For fleury (see below).
     */
    private bool doAllVerticesHaveEvenDegree()
    {
        foreach(vertex; vertices.byValue()) {
            if(vertex.degree % 2 != 0) {
                return false;
            }
        }

        return true;
    }

    /**
     * Implements Fleury's algorithm to find an Euler circuit
     * in the graph. It also indicates if the graph's connected.
     *
     * Params:
     *      isGraphConnected = Boolean to store if the graph's connected
     *
     * Returns: A list with the circuit.
     * Throws: Exception if there's a vertex in the graph with odd degree or
     * the graph is empty.
     */
    // import std.container: DList;
    // public DList!(VType) fleury(ref bool isGraphConnected)
    public auto fleury(ref bool isGraphConnected)
    {
        import datastruct.directed.digraph: Digraph;
        import std.container: DList;
        import std.exception: enforce;
        import std.stdio: writeln;
        import std.algorithm: canFind;
        enforce(!isEmpty, "Can't run Fleury's algorithm in an empty graph.");
        enforce(doAllVerticesHaveEvenDegree(), "Can't run Fleury's algorithm, not every vertex has even degree.");

        auto graph = copy();
        auto circuit = new Digraph!(VType, EType)();
        isGraphConnected = false;

        if(graph.numVertices == 1 && graph.numEdges == 0) {
            isGraphConnected = true;
            circuit.addVertex(graph.vertices.keys[0]);
            return circuit;
        }

        // Auxiliary booleans.
        bool[VType] touched;
        foreach(vertex; graph.vertices.byKey()) {
            touched[vertex] = false;
        }

        VType next;
        // auto circuit = DList!VType();
        auto available = DList!VType(); // Stack of vertices.
        auto lonely = DList!VType(); // Queue of vertices.
        VType stack, queue; // Current 'pointers' for the stack and queue.

        // Selecting an arbitrary initial vertex.
        stack = queue = graph.vertices.keys[0];
        available.insertBack(stack);

        while(graph.vertices[stack].edges.length > 0 || graph.vertices[queue].edges.length > 0) {
            // Looking for an available edge that isn't a bridge.
            foreach(edge; graph.vertices[stack].edges) {
                next = edge.terminus;
                if(graph.vertices[next].degree > 1) {
                    touched[next] = true;
                    available.insertFront(next);
                    graph.removeEdge(stack, next, edge.weight);
                    stack = next;
                    break;
                }
            }

            // Looking if queue is finally a bridge.
            if(graph.vertices[queue].degree == 1) {
                touched[queue] = true;
                lonely.insertBack(queue);
                next = graph.vertices[queue].edges[0].terminus;
                graph.removeEdge(queue, next, graph.vertices[queue].edges[0].weight);
                queue = next;
            }
        }

        // Time to reconstruct that path.
        int lonelySize = 0;
        foreach(vertex; lonely) {
            circuit.addVertex(vertex);
            lonelySize++;
        }

        int availableSize = 0;
        foreach(vertex; available) {
            circuit.addVertex(vertex);
            availableSize++;
        }

        // Adding every arc.
        auto lonelyArray = new VType[lonelySize];
        int i = 0;
        foreach(vertex; lonely) {
            lonelyArray[i] = vertex;
            i++;
        }

        EType currentEdge = 1;
        for(auto j = 0; j < lonelySize - 1; j++) {
            circuit.addArc(lonelyArray[j], lonelyArray[j+1], currentEdge);
            currentEdge++;
        }

        auto availableArray = new VType[availableSize];
        i = 0;
        foreach(vertex; available) {
            availableArray[i] = vertex;
            i++;
        }

        circuit.addArc(lonelyArray[lonelySize-1], availableArray[0], currentEdge);
        currentEdge++;

        for(auto j = 0; j < availableSize - 1; j++) {
            circuit.addArc(availableArray[j], availableArray[j+1], currentEdge);
            currentEdge++;
        }


        // circuit ~= lonely[];
        // circuit ~= available[];

        if(!canFind(touched.values, false) && graph.numEdges == 0) {
            isGraphConnected = true;
        }

        return circuit;
    }

    /**
     * Creates an expansion tree using Breadth-First search.
     *
     * Params:
     *      isGraphConnected = Boolean used to store whether or not the graph's connected
     *
     * Returns: An expansion tree.
     * Throws: Exception if the graph's empty.
     */
    public Graph!(VType, EType) bfs(ref bool isGraphConnected)
    {
        import std.exception: enforce;
        import std.container: DList;
        enforce(!isEmpty, "Can't find an expansion tree on an empty graph.");

        auto tree = new Graph!(VType, EType)();
        auto queue = DList!VType();

        auto current = vertices.keys[0];
        queue.insertBack(current);
        tree.addVertex(current);
        tree.vertices[current].level = 0;
        isGraphConnected = false;

        while(!queue.empty) {
            // Getting a new vertex.
            current = queue.front;
            queue.removeFront();

            foreach(edge; vertices[current].edges) {
                auto terminus = edge.terminus;
                if(terminus !in tree.vertices) {
                    tree.addVertex(terminus);
                    tree.vertices[terminus].level = tree.vertices[current].level + 1;
                    tree.addEdge(current, terminus, edge.weight);

                    if(tree.numVertices == numVertices) {
                        isGraphConnected = true;
                        return tree;
                    }

                    queue.insertBack(terminus);
                }
            }
        }

        if(tree.numVertices == numVertices) {
            isGraphConnected = true;
        }

        return tree;
    }

    /**
     * Iteratively creates an expansion tree using Depth-First search.
     *
     * Params:
     *      isGraphConnected = Boolean used to store whether or not the graph's connected
     *
     * Returns: An expansion tree.
     * Throws: Exception if the graph's empty.
     */
    public Graph!(VType, EType) idfs(ref bool isGraphConnected)
    {
        import std.exception: enforce;
        import std.container: DList;
        enforce(!isEmpty, "Can't find an expansion tree on an empty graph.");

        auto tree = new Graph!(VType, EType)();
        auto next = DList!VType();
        isGraphConnected = false;

        // Adding the root.
        auto current = vertices.keys[0];
        tree.addVertex(current);
        tree.vertices[current].level = 0;
        next.insertFront(current);

        while(!next.empty) {
            auto found = false;

            foreach(edge; vertices[current].edges) {
                auto terminus = edge.terminus;

                if(terminus !in tree.vertices) {
                    tree.addVertex(terminus);
                    tree.vertices[terminus].level = tree.vertices[current].level + 1;
                    tree.addEdge(current, terminus, edge.weight);

                    if(tree.numVertices == numVertices) {
                        isGraphConnected = true;
                        return tree;
                    }

                    next.insertFront(current);
                    current = terminus;
                    found = true;
                    break;
                }
            }

            if(!found) {
                current = next.front;
                next.removeFront();
            }
        }

        if(tree.numVertices == numVertices) {
            isGraphConnected = true;
        }

        return tree;
    }

    /**
     * Recursively creates an expansion tree using Depth-First search.
     *
     * Params:
     *      isGraphConnected = Boolean used to store whether or not the graph's connected
     *
     * Returns: An expansion tree.
     * Throws: Exception if the graph's empty.
     */
    public Graph!(VType, EType) rdfs(ref bool isGraphConnected)
    {
        import std.exception: enforce;
        enforce(!isEmpty, "Can't find an expansion tree on an empty graph.");

        // Adding the root.
        auto tree = new Graph!(VType, EType)();
        auto root = vertices.keys[0];
        tree.addVertex(root);
        tree.vertices[root].level = 0;

        rdfs(root, tree);

        if(tree.numVertices == numVertices) isGraphConnected = true;
        else isGraphConnected = false;

        return tree;
    }

    /**
     * Finds the next edge to be added in a subtree rooted at the given vertex.
     *
     * Params:
     *      root = Root of the subtree
     *      tree = Expansion tree to be updated
     */
    private void rdfs(ref VType root, ref Graph!(VType, EType) tree)
    {
        foreach(edge; vertices[root].edges) {
            auto terminus = edge.terminus;

            if(terminus !in tree.vertices) {
                tree.addVertex(terminus);
                tree.vertices[terminus].level = tree.vertices[root].level + 1;
                tree.addEdge(root, terminus, edge.weight);

                rdfs(terminus, tree);
            }
        }
    }

    /**
     * Uses Kruskal's algorithm to find a minimum expansion tree on the graph.
     *
     * Params:
     *      hasTree = Boolean to store if the graph has a minimum expansion tree
     *      totalWeight = Variable to store the total weight of the tree
     *
     * Returns: A minimum expansion tree as a new instance of a Graph.
     */
    public Graph!(VType, EType) kruskal(ref bool hasTree, ref EType totalWeight)
    {
        import datastruct.heap;
        import std.algorithm.comparison: min;

        auto orderedEdges = new Heap!(Edge!(VType, EType), EType)(numEdges);
        auto tree = new Graph!(VType, EType)();
        enum blank = 0; // Constant for indicating a vertex without a subtree.
        totalWeight = 0;
        hasTree = false;

        // Adding every edge to the heap.
        foreach(vertex; vertices.byValue()) {
            foreach(edge; vertex.edges) {
                orderedEdges.insert(edge, edge.weight);
            }
        }

        // Putting every vertex on a blank subtree.
        int[VType] subtrees;
        foreach(vertex; vertices.byKey()) {
            subtrees[vertex] = blank;
        }

        auto currentTree = 1;
        while(tree.numEdges != numVertices - 1) {
            if(orderedEdges.isEmpty && tree.numEdges != numVertices - 1) {
                hasTree = false;
                return tree;
            }

            auto minEdge = orderedEdges.deleteTop();

            // Checking for both new vertices.
            if(subtrees[minEdge.source] == blank && subtrees[minEdge.terminus] == blank) {
                tree.addVertex(minEdge.source);
                tree.addVertex(minEdge.terminus);
                tree.addEdge(minEdge.source, minEdge.terminus, minEdge.weight);

                currentTree++;
                subtrees[minEdge.source] = currentTree;
                subtrees[minEdge.terminus] = currentTree;

                totalWeight += minEdge.weight;
            // Checking for just one new vertex.
            } else if(subtrees[minEdge.source] == blank || subtrees[minEdge.terminus] == blank) {
                auto unlabeled = subtrees[minEdge.source] == blank? minEdge.source: minEdge.terminus;
                auto labeled = subtrees[minEdge.source] == blank? minEdge.terminus: minEdge.source;

                tree.addVertex(unlabeled);
                tree.addEdge(labeled, unlabeled, minEdge.weight);
                subtrees[unlabeled] = subtrees[labeled];

                totalWeight += minEdge.weight;
            // Merging two different subtrees.
            } else if(subtrees[minEdge.source] != subtrees[minEdge.terminus]) {
                tree.addEdge(minEdge.source, minEdge.terminus, minEdge.weight);
                mergeTrees(subtrees, subtrees[minEdge.source], subtrees[minEdge.terminus]);
                totalWeight += minEdge.weight;
            }
        }

        // Finished succesfully.
        hasTree = true;
        return tree;
    }

    /**
     * Replaces the label of a subtree for another one.
     *
     * Params:
     *      subtrees = Dictionary with the label of the subtree of all vertices
     *      newLabel = New label for the given subtree
     *      oldLabel = Label for the subtree to be merged
     */
    private void mergeTrees(ref int[VType] subtrees, int newLabel, int oldLabel)
    {
        foreach(vertex; subtrees.byKey()) {
            if(subtrees[vertex] == oldLabel) {
                subtrees[vertex] = newLabel;
            }
        }
    }

    /**
     * Uses Prim's algorithm to find a minimum expansion tree on the graph.
     *
     * Params:
     *      hasTree = Boolean to store if the graph has a minimum expansion tree
     *      totalWeight = Variable to store the total weight of the tree
     *
     * Returns: A minimum expansion tree as a new instance of a Graph.
     */
    public Graph!(VType, EType) prim(ref bool hasTree, ref EType totalWeight)
    {
        bool edgeFound;
        auto tree = new Graph!(VType, EType)();

        // Adding an arbitrary root.
        tree.addVertex(vertices.keys[0]);
        totalWeight = 0;

        while(tree.numVertices < numVertices) {
            auto minEdge = findMinimumEdge(tree, edgeFound);

            if(edgeFound) {
                tree.addVertex(minEdge.terminus);
                tree.addEdge(minEdge.source, minEdge.terminus, minEdge.weight);
                totalWeight += minEdge.weight;
            } else {
                break;
            }
        }

        if(tree.numVertices == numVertices) {
            hasTree = true;
        } else {
            hasTree = false;
        }

        return tree;
    }

    /**
     * Finds the edge with minimum weight connecting a vertex in an expansion
     * tree to a vertex not yet in it. Only intended to be usen by prim above.
     *
     * Params:
     *      tree = Current minimum expansion tree
     *      edgeFound = Boolean to store if such an edge was found
     *
     * Returns: Edge with minimum weight.
     */
    private Edge!(VType, EType) findMinimumEdge(ref Graph!(VType, EType) tree, ref bool edgeFound)
    {
        auto minimumEdge = vertices[vertices.keys[0]].edges[0];
        auto minimumWeight = EType.max;
        edgeFound = false;

        foreach(vertex; tree.vertices.byKey()) {
            foreach(edge; vertices[vertex].edges) {
                if(edge.terminus !in tree.vertices && edge.weight < minimumWeight) {
                    minimumEdge = edge;
                    minimumWeight = edge.weight;
                    edgeFound = true;
                }
            }
        }

        return minimumEdge;
    }
}
