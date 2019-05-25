/**
 * This module implements a data structure for a Network, as well as
 * the algorithms that were seen in the course.
 *
 * Author: Ivan A. Moreno Soto
 * Date: May 3, 2019
 */
module datastruct.directed.network;

/**
 * Container for the attributes of a vertex of a network.
 */
struct Vertex(VType, EType) {
    VType name;
    size_t inDegree, outDegree;
    Arc!(VType, EType)[VType] inArcs;
    Arc!(VType, EType)[VType] outArcs;
}

/**
 * Container for the attributes of an arc of a digraph.
 */
struct Arc(VType, EType) {
    EType capacity, restriction, flow, cost;
    // Don't need pointers thanks to the dictionary used by Vertex.
    VType source, terminus, opposite;
}

/**
 * Class that implements a container for the attributes of a network as
 * well as algorithms for it.
 * EType is the type for the weights of the arcs.
 */
class Network(EType) {
    private Vertex!(string, EType)[string] vertices;
    private size_t numVertices, numArcs;
    private EType currentFlow, currentCost;
    /// The user can't add vertices with the following names because they're used in the algorithms.
    static string[] reservedNames = ["a'", "z'", "a''", "z''"];

    /**
     * Constructs an empty network.
     */
    this()
    {
        numVertices = numArcs = 0;
        currentFlow = currentCost = 0;
    }

    /**
     * Removes every vertex and every arc from the graph.
     */
    public void empty()
    {
        vertices.clear;
        numVertices = numArcs = 0;
        currentFlow = currentCost = 0;
    }

    /**
     * Adds a new vertex to the graph with the given identifier. If the identifier
     * is already associated with a vertex, the function returns.
     *
     * Params:
     *      name = Identifier for the new vertex
     */
    public void addVertex(string name)
    {
        if((name in vertices) !is null) {
            return;
        }

        vertices[name] = Vertex!(string, EType)(name, 0, 0);//, [], []);
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
    public void removeVertex(string name)
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(name in vertices, format("Tried to erase vertex %s but it isn't on the network.", name));

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
    public void disconnectVertex(string name)
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(name in vertices, format("Tried to disconnect vertex %s but it isn't on the digraph.", name));

        foreach(arc; vertices[name].outArcs.byValue) {
            removeArc(arc.source, arc.terminus);
        }

        foreach(arc; vertices[name].inArcs.byValue) {
            removeArc(arc.source, arc.terminus);
        }
    }

    /**
     * Adds an arc between two vertices with the given attributes.
     *
     * Params:
     *      source = Identifier for the source vertex
     *      terminus = Identifier for the terminus vertex
     *      capacity = capacity of the new arc
     *      restriction = Minimum restriction of the new arc
     *      flow = Initial flow of the new arc
     *      cost = Per unit of flow cost of the new arc
     *
     * Throws: Exception in the following cases:
     *      - Capacity is negative
     *      _ Capacity is smaller than the minimum restriction
     *      - The minimum restriction is negative
     *      - The initial flow is negative or greater than the capacity
     *      - Either the source or the terminus don't exist
     *      - There's already an arc between the given vertices
     *      - There's an attempt at adding a loop
     */
    public void addArc(string source, string terminus, EType capacity, EType restriction = 0, EType flow = 0, EType cost = 1)
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(source in vertices, "Tried to add an arc from an inexistent vertex.");
        enforce(terminus in vertices, "Tried to add an arc to an inexistent vertex.");
        enforce(source != terminus, format("Can't add a loop in vertex %s.", source));
        enforce(!doesVertexHaveArc(source, terminus), format("Can't add a parallel arc between vertices %s and %s.", source, terminus));

        enforce(capacity >= 0, format("Can't add an arc with negative capacity. capacity given: %s.", capacity));
        enforce(capacity >= restriction, "Can't add an arc with an invalid restriction.");
        enforce(restriction >= 0, "Can't add an arc with an invalid restriction (negative minimum restriction).");
        enforce(flow <= capacity, format("Can't add an arc with overflow. Flow: %s, maximum: %s.", flow, capacity));
        enforce(flow >= 0, format("Can't add an arc with underflow. Flow: %s.", flow));

        vertices[source].outArcs[terminus] = Arc!(string, EType)(capacity, restriction, flow, cost, source, terminus, terminus);
        vertices[source].outDegree++;

        vertices[terminus].inArcs[source] = Arc!(string, EType)(capacity, restriction, flow, cost, source, terminus, source);
        vertices[terminus].inDegree++;

        numArcs++;
    }

    /**
     * Removes an arc between the given vertices.
     *
     * Params:
     *      source = Identifier for the source vertex
     *      terminus = Identifier for the terminus vertex
     *
     * Throws: Exception if any of the identifiers don't exist in the digraph or the
     * specified arc doesn't exist.
     */
    public void removeArc(string source, string terminus)
    {
        import std.exception: enforce;

        enforce(source in vertices, "Tried to remove an arc from an inexistent vertex.");
        enforce(terminus in vertices, "Tried to remove an arc to an inexistent vertex.");
        enforce(terminus in vertices[source].outArcs, "Tried to remove an inexistent arc.");
        enforce(source in vertices[terminus].inArcs, "Tried to remove an inexistent arc.");

        vertices[source].outArcs.remove(terminus);
        vertices[source].outDegree--;

        vertices[terminus].inArcs.remove(source);
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
    public auto doesVertexHaveArc(string source, string terminus)
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(source in vertices, format("Cannot look for an arc in an inexistent vertex: %s.", source));

        return (terminus in vertices[source].outArcs) !is null;
    }

    /**
     * Copies the contents of the network to a new Network instance.
     *
     * Returns: The new Network object.
     */
    auto copy()
    {
        auto networkCopy = new Network!(EType);

        foreach(vertex; vertices.byKey) {
            networkCopy.addVertex(vertex);
        }

        foreach(vertex; vertices.byKey) {
            foreach(arc; vertices[vertex].outArcs.byValue) {
                networkCopy.addArc(arc.source, arc.terminus, arc.capacity, arc.restriction, arc.flow, arc.cost);
            }
        }

        networkCopy.currentFlow = currentFlow;
        networkCopy.currentCost = currentCost;

        return networkCopy;
    }

    /**
     * Prints the contents of the digraph to the standard output.
     */
    public void print() const
    {
        import std.stdio: write, writeln;
        import std.string: format;

        foreach(vertex; vertices.byValue) {
            write(format("%s(+degree: %s, -degree: %s): ", vertex.name, vertex.outDegree, vertex.inDegree));
            foreach(arc; vertex.outArcs.byValue) {
                write(format("%s(q: %s, r: %s, f: %s, c: %s) ", arc.terminus, arc.capacity, arc.restriction, arc.flow, arc.cost));
            }
            write('\n');
        }
        writeln(format("The network has %s vertice(s) and %s arc(s). Current flow: %s. Current cost: %s.", numVertices, numArcs, currentFlow, currentCost));
    }

    /**
     * Takes a Networkx JSON file and creates a Network from it.
     *
     * Params:
     *      filePath = Path to the JSON file
     *      sources = Array in which to store the sources of the network
     *      sinks = Array in which to store the sinks of the network
     *      vertexRestrictions = Dictionary in which to store vertices' restrictions
     *      productions = Dictionary in which to store vertices' productions/demands
     *
     * Returns: Digraph instance with the information contained in filePath.
     */
    public auto loadFromNxJSON(string filePath, ref string[] sources, ref string[] sinks, ref EType[][string] vertexRestrictions, ref EType[string] productions)
    {
        import std.json;
        import std.stdio: File;

        // Reading and parsing the input graph.
        auto outputFile = File(filePath, "r");
        auto fileContents = outputFile.readln();
        JSONValue jsonGraph = parseJSON(fileContents);

        // Creating the new graph from the JSON.
        auto graph = new Network!(EType)();
        foreach(vertex; jsonGraph["nodes"].array) {
            graph.addVertex(vertex["id"].str);
            if(vertex["type"].str == "source") {
                sources ~= vertex["id"].str;
            } else if(vertex["type"].str == "sink") {
                sinks ~= vertex["id"].str;
            }

            if("min_flow" in vertex) {
                vertexRestrictions[vertex["id"].str] = [vertex["max_flow"].integer, vertex["min_flow"].integer];
            } else if("flow" in vertex) {
                productions[vertex["id"].str] = vertex["flow"].integer;
            }
        }
        foreach(edge; jsonGraph["links"].array) {
            graph.addArc(edge["source"].str, edge["target"].str, edge["weight"].integer, edge["restriction"].integer, edge["flow"].integer, edge["cost"].integer);
        }

        return graph;
    }

    /**
     * Saves the network in a text file with a format useful
     * for Networkx (in Python).
     * Text file format:
     *      network header -> network
     *      vertices header -> vertex
     *      vertices -> name type r restrictions p production/demand
     *      arcs header -> edges
     *      arcs -> source terminus weight restriction flow cost
     *      extra information -> key value
     *      footer -> end
     *
     * Params:
     *      id = ID for the text file
     *      sources = Array with the sources of the network
     *      sinks = Array with the sinks of the network
     *      vertexRestrictions = Dictionary with the vertices' restrictions
     *      productions = Dictionary with the vertices' productions/demands
     *      additionalInfo = Additional information accompanying the network
     */
    public void saveToFile(string id, string[] sources, string[] sinks, EType[][string] vertexRestrictions, EType[string] productions, string[] additionalInfo = null)
    {
        import std.stdio: File;
        import std.string: format;
        import std.algorithm.searching: canFind;

        string filePath = format("../../data/%s-final.txt", id);
        auto outputFile = File(filePath, "w");
        // Header.
        outputFile.writeln("network");
        // Vertices.
        string type, minRest, maxRest, prod;

        outputFile.writeln("vertex");
        foreach(vertex; vertices.byKey) {
            if(canFind(sources, vertex)) {
                type = "source";
            } else if(canFind(sinks, vertex)) {
                type = "sink";
            } else {
                type = "pass";
            }

            if(vertex in vertexRestrictions) {
                minRest = format("%s", vertexRestrictions[vertex][1]);
                maxRest = format("%s", vertexRestrictions[vertex][0]);
            } else {
                minRest = "";
                maxRest = "";
            }

            if(vertex in productions) {
                prod = format("%s", productions[vertex]);
            } else {
                prod = "";
            }

            // outputFile.writeln(vertex);
            outputFile.writeln(format("%s %s r %s %s p %s", vertex, type, minRest, maxRest, prod));
        }
        // Arcs.
        outputFile.writeln("edges");
        foreach(vertex; vertices.byKey) {
            foreach(arc; vertices[vertex].outArcs) {
                outputFile.writeln(format("%s %s %s %s %s %s", arc.source, arc.terminus, arc.capacity, arc.restriction, arc.flow, arc.cost));
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
     * Returns true if name exists in the digraph, false otherwise.
     */
    public bool isVertexOnNetwork(string name) const
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
    public auto getVertexDegree(string name) const
    {
        import std.exception: enforce;
        import std.string: format;
        enforce(name in vertices, format("Tried to get the degree for vertex %s that isn't on the digraph.", name));

        return vertices[name].outDegree + vertices[name].inDegree;
    }

    /**
     * Returns the current number of vertices in the network.
     */
    public auto numberVertices() const @property
    {
        return numVertices;
    }

    /**
     * Returns the current number of arcs in the network.
     */
    public auto numberArcs() const @property
    {
        return numArcs;
    }

    /**
     * Returns the current flow of the network.
     */
    public auto flow() const @property
    {
        return currentFlow;
    }

    /**
     * Returns the current cost of routing in the network.
     */
    public auto cost() @property
    {
        return currentCost;
    }

    /**
     * Returns true if the network is empty, false otherwise.
     */
    public bool isEmpty() const @property
    {
        return numVertices == 0;
    }

    /**
     * Constructs the marginal network associated with this.
     *
     * Params:
     *      capacities = Associative array to store the capacities of each arc
     *
     * Returns: A marginal network as a Digraph instance.
     */
    public auto constructMarginalNetwork(ref EType[string][string] capacities)
    {
        import datastruct.directed.digraph: Digraph;
        auto marginal = new Digraph!(string, EType)();

        // Adding every vertex to the marginal network.
        foreach(vertex; vertices.byKey) {
            marginal.addVertex(vertex);
        }

        foreach(vertex; vertices.byKey) {
            foreach(arc; vertices[vertex].outArcs.byValue) {
                // Can pass more flow through this arc.
                if(arc.flow < arc.capacity) {
                    marginal.addArc(vertex, arc.terminus, arc.cost);
                    capacities[vertex][arc.terminus] = arc.capacity - arc.flow;
                }
                // Can pass less flow through this arc.
                if(arc.flow > arc.restriction) {
                    marginal.addArc(arc.terminus, vertex, -arc.cost);
                    capacities[arc.terminus][vertex] = arc.flow - arc.restriction;
                }
            }
        }

        return marginal;
    }

    /**
     * Returns true if there's at least one restriction in the network.
     */
    private auto areThereRestrictionsInThisNetwork() @property
    {
        foreach(vertex; vertices.byKey) {
            foreach(arc; vertices[vertex].outArcs.byValue) {
                if(arc.restriction > 0) return true;
            }
        }
        return false;
    }

    /**
     * Returns true if an initial flow was found.
     */
    private auto initialFlowFound() @property
    {
        foreach(arc; vertices["a''"].outArcs.byValue) {
            if(arc.flow < arc.capacity) {
                return false;
            }
        }
        return true;
    }

    /**
     * Copies the flow of every arc from another network onto this one.
     *
     * Params:
     *      network = Network to copy flow from
     */
    private void copyFlow(Network!(EType) network) @property
    {
        foreach(vertex; network.vertices.byKey) {
            if(vertex !in vertices) continue;

            foreach(arc; network.vertices[vertex].outArcs.byValue) {
                if(arc.terminus !in vertices[vertex].outArcs) continue;

                vertices[vertex].outArcs[arc.terminus].flow = network.vertices[vertex].outArcs[arc.terminus].flow;
                vertices[arc.terminus].inArcs[vertex].flow = network.vertices[vertex].outArcs[arc.terminus].flow;
            }
        }
    }

    /**
     * Computes the maximum possible flow through this network using Ford-Fulkerson's
     * algorithm.
     *
     * Params:
     *      source = Identifier for the source
     *      sink = Identifier for the sink
     *      verbose = Whether to print each step of the optimization
     *      targetFlow = Target flow to obtain
     *
     * Returns: A Network object with the optimized flow.
     */
    private auto fordFulkerson(string source, string sink, bool verbose = true, EType* targetFlow = null)
    {
        import std.algorithm.comparison: min;
        import std.stdio: write, writeln;
        import std.string: format;

        auto network = copy();
        bool chainFound = true;
        // Possible states for the vertices.
        enum {unset = 0, touched = 1, examined = 2}

        // Auxiliar dictionaries.
        int[string] states;
        string[string] previous;
        bool[string] operation; // true for +, false for -.
        EType[string] chainCapacity;

        // We start by resetting the labels of every vertex.
        foreach(vertex; vertices.byKey) {
            states[vertex] = unset;
        }

        // We set the initial attributes on the source.
        states[source] = touched;
        previous[source] = source;
        operation[source] = true;
        chainCapacity[source] = EType.max;

        // We look for chains.
        while(chainFound) {
            // Find a vertex to be examined.
            string vertex;
            bool vertexFound = false;
            foreach(v; vertices.byKey) {
                if(states[v] == touched) {
                    vertex = v;
                    vertexFound = true;
                    break;
                }
            }

            // All vertex are examined. There isn't a chain.
            if(!vertexFound) {
                chainFound = false;
                continue;
            }

            // Looking at all arcs that come out of this vertex.
            foreach(arc; network.vertices[vertex].outArcs.byValue) {
                // We can pass more flow through this arc.
                if(states[arc.terminus] == unset && arc.flow < arc.capacity) {
                    states[arc.terminus] = touched;
                    previous[arc.terminus] = vertex;
                    operation[arc.terminus] = true;
                    chainCapacity[arc.terminus] = min(chainCapacity[vertex], arc.capacity - arc.flow);
                }
            }

            // Looking at all arcs that come into this vertex.
            foreach(arc; network.vertices[vertex].inArcs.byValue) {
                // We can pass less flow through this arc.
                if(states[arc.terminus] == unset && arc.flow > arc.restriction) {
                    states[arc.terminus] = touched;
                    previous[arc.terminus] = vertex;
                    operation[arc.terminus] = false;
                    chainCapacity[arc.terminus] = min(chainCapacity[vertex], arc.flow - arc.restriction);
                }
            }

            // We finished examining this vertex.
            states[vertex] = examined;

            // We update the network if we found a chain.
            if(states[sink] != unset) {
                if(targetFlow !is null) {
                    chainCapacity[sink] = min(chainCapacity[sink], *targetFlow - network.currentFlow);
                }

                for(auto updated = sink; updated != source; updated = previous[updated]) {
                    if(operation[updated]) { // If we need to increment the flow.
                        network.vertices[previous[updated]].outArcs[updated].flow += chainCapacity[sink];
                        network.vertices[updated].inArcs[previous[updated]].flow += chainCapacity[sink];
                    } else { // If we need to decrement the flow.
                        network.vertices[previous[updated]].inArcs[updated].flow -= chainCapacity[sink];
                        network.vertices[updated].outArcs[previous[updated]].flow -= chainCapacity[sink];
                    }
                }

                network.currentFlow += chainCapacity[sink];
                // Resetting the labels again.
                foreach(v; vertices.byKey) {
                    states[v] = unset;
                }

                if(verbose) {
                    writeln(format("An augmenting chain was found with capacity %s.", chainCapacity[sink]));
                    writeln("Current state of the network after the latest changes:");
                    network.print();
                    write('\n');
                }

                if(targetFlow !is null && network.currentFlow == *targetFlow) {
                    chainFound = false;
                    continue;
                }

                // We set the initial labels on the source.
                states[source] = touched;
                previous[source] = source;
                operation[source] = true;
                chainCapacity[source] = EType.max;
            }
        }

        return network;
    }

    /**
     * Takes a network with arc and vertices restrictions, and makes the necessary
     * transformations to find the maximum flow.
     *
     * Params:
     *      sources = Array with identifiers of every source vertex
     *      sinks = Array with identifiers of every sink vertex
     *      vertexRestrictions = Associative array that associates a vertex with its
     *      minimum and maximum restrictions
     *      verbose = Whether to print each step of the optimization
     *      targetFlow = Target flow to obtain
     *
     * Returns: A new Network instance with the maximum flow.
     * Throws: Exception if any of the following happen:
     *      - sources or sinks are empty
     *      - Any source or sink doesn't exist
     *      - Any vertex has an invalid restriction
     *      - An initial flow wasn't found (if there are arc restrictions)
     */
    auto fordFulkerson(string[] sources, string[] sinks, EType[][string] vertexRestrictions = null, bool verbose = true, EType* targetFlow = null)
    {
        import std.algorithm.comparison: min;
        import std.exception: enforce;

        import std.stdio: write, writeln;
        import std.string: format;

        enforce(sources.length > 0, "Cannot run Ford-Fulkerson with no sources.");
        enforce(sinks.length > 0, "Cannot run Ford-Fulkerson with no sinks.");

        auto network = makeTransformations(sources, sinks, vertexRestrictions);
        if(verbose) {
            writeln("Network after transforming restrictions for vertices:");
            network.print();
        }
        network.findInitialFlow(targetFlow, verbose);
        network = network.fordFulkerson("a'", "z'", true, targetFlow);
        network = network.revertTransformations(vertexRestrictions);
        if(verbose) {
            writeln("The optimization process has finished.");
        }

        return network;
    }

    /**
     * Computes the total cost of the current routing in the network.
     */
    private auto computeCost() @property
    {
        EType cost = 0;
        foreach(vertex; vertices.byValue) {
            foreach(arc; vertex.outArcs.byValue) {
                cost += arc.flow * arc.cost;
            }
        }

        return cost;
    }

    /**
     * Transforms the arc restrictions of the network and finds an initial flow.
     *
     * Params:
     *      targetFlow = Desired flow. If null, just searches for the maximum possible flow
     *      verbose = Wheter to indicate or not each step of the process
     *
     * Throws: Exception if the network doesn't have a solution with the given restrictions.
     */
    private void findInitialFlow(EType* targetFlow, bool verbose = true)
    {
        import std.exception: enforce;
        import std.stdio: write, writeln;
        import std.algorithm.comparison: min;

        auto initFlowNetwork = copy();
        auto supersupersource = "a''";
        auto supersupersink = "z''";
        auto supersource = "a'";
        auto supersink = "z'";

        initFlowNetwork.addVertex(supersupersource);
        initFlowNetwork.addVertex(supersupersink);
        initFlowNetwork.addArc(supersource, supersink, EType.max);
        initFlowNetwork.addArc(supersink, supersource, EType.max);

        foreach(vertex; initFlowNetwork.vertices.byKey) {
            EType minFlow = 0;
            // Adding up every arc restriction.
            foreach(ref arc; initFlowNetwork.vertices[vertex].outArcs.byValue) {
                if(arc.restriction > 0) {
                    minFlow += arc.restriction;
                    arc.capacity -= arc.restriction;
                    arc.restriction = 0;
                }
            }
            if(minFlow > 0) {
                initFlowNetwork.addArc(vertex, supersupersink, minFlow);
            }

            minFlow = 0;
            // Adding up every arc restriction.
            foreach(ref arc; initFlowNetwork.vertices[vertex].inArcs.byValue) {
                minFlow += arc.restriction;
                if(arc.restriction > 0) {
                    arc.capacity -= arc.restriction;
                    arc.restriction = 0;
                }
            }
            if(minFlow > 0) {
                initFlowNetwork.addArc(supersupersource, vertex, minFlow);
            }
        }

        initFlowNetwork = initFlowNetwork.fordFulkerson(supersupersource, supersupersink, verbose);
        enforce(initFlowNetwork.initialFlowFound(), "The network has no solution with the restrictions given.");

        if(verbose) {
            writeln("Network after finding an initial flow:");
            initFlowNetwork.print();
            write('\n');
        }

        copyFlow(initFlowNetwork);
        currentFlow = initFlowNetwork.vertices[supersink].outArcs[supersource].flow;
        if(targetFlow !is null) {
            enforce(currentFlow <= *targetFlow, "Can't find the given target flow.");
        }

        // We start examining every arc that enters the supersupersink.
        foreach(initArc; initFlowNetwork.vertices[supersupersink].inArcs.byValue) {
            // We distribute the arc's flow between all of the arcs with restrictions.
            while(initArc.flow > 0) {
                foreach(ref arc; vertices[initArc.source].outArcs.byValue) {
                    if(arc.restriction > 0 && arc.flow < arc.capacity) {
                        auto delta = min(arc.restriction, initArc.flow, arc.capacity - arc.flow);
                        arc.flow += delta;
                        initArc.flow -= delta;
                    }
                }
            }
        }

        // We continue examining every arc that exits the supersupersource.
        foreach(initArc; initFlowNetwork.vertices[supersupersource].outArcs.byValue) {
            // We distribute the arc's flow between all of the arcs with restrictions.
            while(initArc.flow > 0) {
                foreach(ref arc; vertices[initArc.terminus].inArcs.byValue) {
                    if(arc.restriction > 0 && arc.flow < arc.capacity) {
                        auto delta = min(arc.restriction, initArc.flow, arc.capacity - arc.flow);
                        arc.flow += delta;
                        initArc.flow -= delta;
                    }
                }
            }
        }

        if(verbose) {
            writeln("Network after transforming back from the additional arcs:");
            print();
            write('\n');
        }
    }

    /**
     * Makes the necessary transformations for vertices restrictions and multisources
     * and multisinks for the second part of the algorithm for minimum cost flow.
     *
     * Params:
     *      sources = Array with identifiers of every source vertex
     *      sinks = Array with identifiers of every sink vertex
     *      vertexRestrictions = Associative array that associates a vertex with its
     *
     * Returns: Network with the transformations.
     */
    private auto makeTransformations(string[] sources, string[] sinks, EType[][string] restrictions = null)
    {
        auto network = copy();
        auto supersource = "a'";
        auto supersink = "z'";
        network.addVertex(supersource);
        network.addVertex(supersink);
        EType flow;

        // Connecting every source and sink to the supersource and supersink.
        foreach(v; sources) {
            flow = 0;
            foreach(arc; network.vertices[v].outArcs.byValue) {
                flow += arc.flow;
            }
            network.addArc(supersource, v, EType.max, 0, flow, 0);
        }

        foreach(v; sinks) {
            flow = 0;
            foreach(arc; network.vertices[v].inArcs.byValue) {
                flow += arc.flow;
            }
            network.addArc(v, supersink, EType.max, 0, flow, 0);
        }

        if(restrictions !is null) {
            // We transform every vertex restriction.
            foreach(item; restrictions.byKeyValue()) {
                // item.value[0] is the maximum flow, item.value[1] is the minimum flow.
                auto imgVertex = item.key ~ "'"; // New dummy vertex.
                network.addVertex(imgVertex);

                flow = 0;
                // Moving every arc to the dummy vertex.
                foreach(arc; network.vertices[item.key].outArcs.byValue) {
                    flow += arc.flow;
                    network.addArc(imgVertex, arc.terminus, arc.capacity, arc.restriction, arc.flow, arc.cost);
                    network.removeArc(arc.source, arc.terminus);
                }

                network.addArc(item.key, imgVertex, item.value[0], item.value[1], flow, 0);
            }
        }

        return network;
    }

    /**
     * Removes every extra extra vertex and extra arc created by the method above.
     *
     * Params:
     *      vertexRestrictions = Associative array that associates a vertex with its
     *
     * Returns: Network without the extra things.
     */
    private auto revertTransformations(EType[][string] restrictions = null)
    {
        auto network = copy();

        if(restrictions !is null) {
            // Erasing every dummy vertex and moving back all the necessary arcs.
            foreach(item; restrictions.byKeyValue()) {
                auto imgVertex = item.key ~ "'";
                foreach(arc; network.vertices[imgVertex].outArcs.byValue) {
                    network.addArc(item.key, arc.opposite, arc.capacity, arc.restriction, arc.flow, arc.cost);
                }
                network.removeVertex(imgVertex);
            }
        }

        network.removeVertex("a'");
        network.removeVertex("z'");

        return network;
    }

    /**
     * Given a flow F, computes the minimum cost routing for it in the network.
     *
     * Params:
     *      F = Desired flow
     *      sources = Array with identifiers of every source vertex
     *      sinks = Array with identifiers of every sink vertex
     *      vertexRestrictions = Associative array that associates a vertex with its
     *      minimum and maximum restrictions
     *      verbose = Whether to print each step of the optimization
     *
     * Returns: Network with minimum cost routing of the flow F.
     * Throws: Exception if any of the following happen:
     *      - sources or sinks are empty
     *      - Any source or sink doesn't exist
     *      - Any vertex has an invalid restriction
     *      - An initial flow wasn't found (if there are arc restrictions)
     *      - Flow F is not possible in the network
     */
    public auto minimumCostFlow(EType F, string[] sources, string[] sinks, EType[][string] vertexRestrictions = null, bool verbose = true)
    {
        import std.exception: enforce;
        import std.stdio: writeln;
        import std.string: format;
        import datastruct.directed.digraph: Digraph;

        // Computing an initial route for flow F.
        auto network = makeTransformations(sources, sinks, vertexRestrictions);
        network.findInitialFlow(&F, verbose);
        network = network.fordFulkerson("a'", "z'", verbose, &F);

        enforce(network.flow == F, format("Flow %s is not possible in this network.", F));
        network.currentCost = network.computeCost;

        if(verbose) {
            writeln(format("Network after finding an initial routing for flow %s.", F));
            network.print();
            writeln("");
        }

        // Optimizing the routing.
        bool minimumCostFound = false;
        while(!minimumCostFound) {
            EType[string][string] capacities;
            auto marginal = network.constructMarginalNetwork(capacities);

            bool cycleFound;
            auto cycle = new Digraph!(string, EType)();
            EType[string] shortestPaths;
            string[string] previous;
            foreach(v; network.vertices.byKey) {
                cycle = marginal.dijkstra(v, cycleFound, shortestPaths, previous);
                if(cycleFound) break;
            }

            if(verbose) {
                writeln("This step's marginal network:");
                marginal.print();
                writeln("");
                writeln("This step's cycle:");
                cycle.print();
                writeln("");
            }

            // We finished.
            if(!cycleFound) {
                minimumCostFound = true;
                continue;
            }

            // Finding the minimum capacity in the cycle.
            auto d = EType.max;
            foreach(vertex; cycle.vertices.byValue) {
                auto arc = vertex.outArcs[0];
                if(capacities[arc.source][arc.terminus] < d) {
                    d = capacities[arc.source][arc.terminus];
                }
            }

            EType cycleCost = 0;
            foreach(vertex; cycle.vertices.byValue) {
                auto arc = vertex.outArcs[0]; // Literally the only arc.
                // When it's in proper orientation.
                if(arc.terminus in network.vertices[arc.source].outArcs) {
                     network.vertices[arc.source].outArcs[arc.terminus].flow += d;
                     network.vertices[arc.terminus].inArcs[arc.source].flow += d;
                 } else {
                     network.vertices[arc.terminus].outArcs[arc.source].flow -= d;
                     network.vertices[arc.source].inArcs[arc.terminus].flow -= d;
                 }
                cycleCost += arc.weight;
            }

            network.currentCost += d * cycleCost;

            if(verbose) {
                writeln(format("Current network. Cycle cost: %s; flow moved: %s; total change %s.", cycleCost, d, d*cycleCost));
                network.print();
                writeln("");
            }
        }

        network = network.revertTransformations(vertexRestrictions);

        return network;
    }

    /**
     * Sets the flow for every arc to 0.
     */
    private void setTrivialFlow()
    {
        foreach(v; vertices.byKey) {
            foreach(u; vertices[v].outArcs.byKey) {
                vertices[v].outArcs[u].flow = 0;
            }

            foreach(u; vertices[v].inArcs.byKey) {
                vertices[v].inArcs[u].flow = 0;
            }
        }

        currentFlow = 0;
    }

    /**
     * Given a flow F, computes the minimum cost routing for it in the network
     * using shortest paths.
     *
     * Params:
     *      F = Desired flow
     *      sources = Array with identifiers of every source vertex
     *      sinks = Array with identifiers of every sink vertex
     *      vertexRestrictions = Associative array that associates a vertex with its
     *      maximum restriction
     *      verbose = Whether to print each step of the optimization
     *
     * Returns: Network with minimum cost routing of the flow F.
     * Throws: Exception if any of the following happen:
     *      - There's a minimum restriction in at least one arc
     *      - sources or sinks are empty
     *      - Any source or sink doesn't exist
     *      - Any vertex has an invalid restriction
     *      - Flow F is not possible in the network
     */
    public auto minimumCostFlowWithShortestPaths(EType F, ref bool solutionFound, string[] sources, string[] sinks, EType[][string] vertexRestrictions = null, bool verbose = true)
    {
        import std.exception: enforce;
        import std.stdio: writeln;
        import std.string: format;
        import std.algorithm.comparison: min;
        import datastruct.directed.digraph: Digraph;

        enforce(sources.length > 0, "Cannot run the algorithm without sources.");
        enforce(sinks.length > 0, "Cannot run the algorithm without sinks.");
        enforce(!areThereRestrictionsInThisNetwork(), "Cannot run the algorithm with arc minimum restrictions.");

        auto network = copy();
        network.setTrivialFlow();

        // EType[][string] restrictions;
        // if(vertexRestrictions !is null) {
        //     foreach(v; vertexRestrictions.byKey) {
        //         restrictions[v] = [vertexRestrictions[v], 0];
        //     }
        // }
        // network = network.makeTransformations(sources, sinks, restrictions);
        network = network.makeTransformations(sources, sinks, vertexRestrictions);
        network.print();

        // Optimizing the routing.
        bool minimumCostFound = false;
        while(!minimumCostFound) {
            EType[string][string] capacities;
            auto residual = network.constructMarginalNetwork(capacities);

            bool cycleFound;
            EType[string] shortest;
            string[string] previous;
            auto shortestPath = residual.dijkstra("a'", cycleFound, shortest, previous);

            if(verbose) {
                writeln("This step's residual network:");
                residual.print();
                writeln("");
                writeln("This step's shortest path:");
                shortestPath.print();
                writeln("");
            }

            if(cycleFound || (shortest["z'"] == EType.max && network.currentFlow != F)) {
                solutionFound = false;
                // network = network.revertTransformations(restrictions);
                network = network.revertTransformations(vertexRestrictions);
                return network;
            }

            // Finding the minimum capacity in the cycle.
            auto d = EType.max;
            for(auto vertex = "z'"; vertex != "a'"; vertex = previous[vertex]) {
                auto arc = shortestPath.vertices[vertex].inArcs[0];
                if(capacities[arc.source][arc.terminus] < d) {
                    d = capacities[arc.source][arc.terminus];
                }
            }

            auto delta = min(d, F - network.currentFlow);
            EType cycleCost = 0;
            for(auto vertex = "z'"; vertex != "a'"; vertex = previous[vertex]) {
                auto arc = shortestPath.vertices[vertex].inArcs[0]; // Literally the only arc.
                // When it's in proper orientation.
                if(arc.terminus in network.vertices[arc.source].outArcs) {
                     network.vertices[arc.source].outArcs[arc.terminus].flow += delta;
                     network.vertices[arc.terminus].inArcs[arc.source].flow += delta;
                 } else {
                     network.vertices[arc.terminus].outArcs[arc.source].flow -= delta;
                     network.vertices[arc.source].inArcs[arc.terminus].flow -= delta;
                 }
                cycleCost += arc.weight;
            }

            network.currentCost += delta * cycleCost;
            network.currentFlow += delta;

            if(verbose) {
                writeln(format("Current network. Cycle cost: %s; flow moved: %s; total change %s.", cycleCost, d, d*cycleCost));
                network.print();
                writeln("");
            }

            if(network.currentFlow == F) {
                solutionFound = true;
                minimumCostFound = true;
            }
        }

        // network = network.revertTransformations(restrictions);
        network = network.revertTransformations(vertexRestrictions);

        return network;
    }
}
