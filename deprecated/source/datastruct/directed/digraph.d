/**
 * This module implements data structures for a Digraph, and a Network, as well as
 * the algorithms that were seen in the course.
 *
 * Author: Ivan A. Moreno Soto
 * Date: April 15, 2019
 */
module datastruct.directed.digraph;

import datastruct.directed.list;

/**
 * Superclass for Digraph and Network. Just used to reduce the amount of repeated
 * code in those classes. Not meant to be used for anything else.
 *
 * VType is the type for the vertex identifier.
 * EType is the type for the arc's weight/flow/minimum. Must have the 'max' attribute
 * defined.
 */
abstract class GenericDirectedGraph(VType, EType) {
protected:
    DVertexList!(VType, EType) vertices;
    size_t numVertices;
    size_t numArcs;

    /**
     * Adds a directed arc between the given vertices with the given attributes.
     *
     * Params:
     *      source = Identifier for the source of the arc
     *      terminus = Identifier for the terminus of the arc
     *      weight = Weight/maximum flow possible of the arc
     *      minimum = Minimum flow restriction of the arc. Must be 0 for a Digraph's arc.
     *      flow = Initial flow of the arc. Must be 0 for a Digraph's arc.
     *
     * Throws: Exception if any of the vertices doesn't exist in the graph.
     */
    void addArc(VType source, VType terminus, EType weight, EType minimum, EType flow)
    {
        import std.exception: enforce;

        auto sourceVertex = vertices.peek(source);
        auto terminusVertex = vertices.peek(terminus);

        enforce(sourceVertex !is null, "Tried to add an arc from an inexistent vertex.");
        enforce(terminusVertex !is null, "Tried to add an arc to an inexistent vertex.");

        sourceVertex.outArcs.append(terminus, weight, minimum, flow, sourceVertex, terminusVertex);
        sourceVertex.outDegree++;

        terminusVertex.inArcs.append(source, weight, minimum, flow, sourceVertex, terminusVertex);
        terminusVertex.inDegree++;

        numArcs++;
    }
public:
    /**
     * Constructs an empty directed graph.
     */
    this()
    {
        numVertices = numArcs = 0;
        vertices = new DVertexList!(VType, EType);
    }

    /**
     * Destroys the vertices in the graph and makes a new empty list.
     */
    void empty()
    {
        destroy(vertices);
        vertices = new DVertexList!(VType, EType);
        numVertices = numArcs = 0;
    }

    /**
     * Adds a vertex with the given identifier. Doesn't allow repetitions.
     *
     * Params:
     *      name = Identifier for the new vertex.
     */
    void addVertex(VType name)
    {
        if(vertices.search(name)) {
            return;
        }

        vertices.append(name);
        numVertices++;
    }

    /**
     * Removes a vertex from the directed graph.
     *
     * Params:
     *      name = Identifier of the vertex that needs to be removed
     *
     * Throws: Exception when the identifier doesn't exist in the directed graph.
     */
    void removeVertex(VType name)
    {
        import std.string: format;
        import std.exception: enforce;

        enforce(vertices.search(name), format("Tried to erase vertex %s but it isn't on the digraph.", name));

        disconnectVertex(name);
        vertices.remove(name);
        numVertices--;
    }

    /**
     * Removes every arc that touches the given vertex.
     *
     * Params:
     *      name = Identifier of the vertex that needs to be disconnected
     *
     * Throws: Exception when the identifier doesn't exist in the directed graph.
     */
    void disconnectVertex(VType name)
    {
        import std.string: format;
        import std.exception: enforce;
        enforce(vertices.search(name), format("Tried to disconnect vertex %s but it isn't on the digraph.", name));

        auto vertex = vertices.peek(name);
        // Every arc that starts from this vertex.
        for(auto arc = vertex.begOutArcs; arc !is null; arc = vertex.begOutArcs) {
            removeArc(vertex.name, arc.terminus.name, arc.weight);
        }
        // Every arc that ends on this vertex.
        for(auto arc = vertex.begInArcs; arc !is null; arc = vertex.begInArcs) {
            removeArc(arc.opposite, vertex.name, arc.weight);
        }
    }

    /**
     * Removes the given arc from the directed graph. Does nothing if the arc doesn't
     * exist.
     *
     * Params:
     *      source = Identifier of the source of the arc
     *      terminus = Identifier of the terminus of the arc
     *      weight = Weight/Maximum flow possible of the arc. Allows removing one of several parallel arcs.
     *
     * Throws: Exception if any of the vertices don't exist.
     */
    void removeArc(VType source, VType terminus, EType weight)
    {
        import std.exception: enforce;

        auto sourceVertex = vertices.peek(source);
        auto terminusVertex = vertices.peek(terminus);

        enforce(sourceVertex !is null, "Tried to remove an arc from an inexistent vertex.");
        enforce(terminusVertex !is null, "Tried to remove an arc to an inexistent vertex.");

        sourceVertex.outArcs.remove(terminus, weight);
        sourceVertex.outDegree--;

        terminusVertex.inArcs.remove(source, weight);
        terminusVertex.inDegree--;

        numArcs--;
    }

    /**
     * Checks if a given vertex is on the graph.
     *
     * Params:
     *      name = Identifier that needs to be searched for
     *
     * Returns: true if a vertex with the given identifier is found, false otherwise.
     */
    bool isVertexOnGraph(VType name)
    {
        return vertices.search(name);
    }

    /**
     * Returns deg+ + deg- of a given vertex.
     *
     * Params:
     *      name = Identifier of the vertex of interest
     *
     * Returns: The sum of both degrees of the given vertex.
     * Throws: Exception if a vertex with the given identifier doesn't exist.
     */
    auto getVertexDegree(VType name)
    {
        import std.string: format;
        import std.exception: enforce;

        auto vertex = vertices.peek(name);
        enforce(vertex !is null, format("Tried to get the degree for vertex %s that isn't on the digraph.", name));

        return vertex.outDegree + vertex.inDegree;
    }

    /**
     * Returns the current number of vertices in the graph.
     */
    auto amountVertices() const @property
    {
        return numVertices;
    }

    /**
     * Returns the current number of arcs in the graph.
     */
    auto amountArcs() const @property
    {
        return numArcs;
    }

    /**
     * Returns true if the graph is empty, false otherwise.
     */
    bool isEmpty() const @property
    {
        return numVertices == 0;
    }

    /**
     * Every derived class must define how to present its contents to the standard
     * output.
     */
    abstract void print();
    /**
     * Every derived class must define how to copy its contents ta a new instance.
     */
    abstract GenericDirectedGraph!(VType, EType) copy();
}

/**
 * Container for a weighted directed graph that also implements a selection of
 * optimization algorithms.
 */
class Digraph(VType, EType): GenericDirectedGraph!(VType, EType) {
public:
    /**
     * Adds an arc with weight 1.
     *
     * Params:
     *      source = Identifier for the source of the arc
     *      terminus = Identifier for the terminus of the arc
     *
     * Throws: Exception if any of the vertices doesn't exist in the graph.
     */
    void addArc(VType source, VType terminus)
    {
        super.addArc(source, terminus, 1, 0, 0);
    }

    /**
     * Adds an arc with the given weight.
     *
     * Params:
     *      source = Identifier for the source of the arc
     *      terminus = Identifier for the terminus of the arc
     *      weight = Weight of the arc
     *
     * Throws: Exception if any of the vertices doesn't exist in the graph.
     */
    void addArc(VType source, VType terminus, EType weight)
    {
        super.addArc(source, terminus, weight, 0, 0);
    }

    /**
     * Removes an arc between the given vertices with an implicit weight of 1.
     *
     * Params:
     *      source = Identifier of the source of the arc
     *      terminus = Identifier of the terminus of the arc
     *
     * Throws: Exception if any of the vertices don't exist.
     */
    void removeArc(VType source, VType terminus)
    {
        super.removeArc(source, terminus, 1);
    }

    /**
     * Prints the contents of the digraph to the standard output. Ignores
     * attributes that are only used in Network.
     */
    override void print()
    {
        import std.stdio: write, writeln;
        import std.string: format;

        for(auto vertex = vertices.beginning; vertex !is null; vertex = vertex.next) {
            write(format("%s(deg+: %s; deg-: %s): ", vertex.name, vertex.outDegree, vertex.inDegree));
            for(auto arc = vertex.begOutArcs; arc !is null; arc = arc.next) {
                write(format("%s(w:%s) ", arc.opposite, arc.weight));
            }
            write('\n');
        }

        writeln(format("The digraph has %s vertice(s) and %s arc(s).", numVertices, numArcs));
    }

    /**
     * Copies the contents of the digraph to a new instance.
     *
     * Returns: A new object with the same vertices and arcs.
     */
    override Digraph!(VType, EType) copy()
    {
        auto digraphCopy = new Digraph!(VType, EType);

        // Adding every vertex.
        for(auto vertex = vertices.beginning; vertex !is null; vertex = vertex.next) {
            digraphCopy.addVertex(vertex.name);
        }

        // Adding ever arc once.
        for(auto vertex = vertices.beginning; vertex !is null; vertex = vertex.next) {
            for(auto arc = vertex.begOutArcs; arc !is null; arc = arc.next) {
                digraphCopy.addArc(vertex.name, arc.opposite, arc.weight);
            }
        }

        return digraphCopy;
    }
}

/**
 * Container for a Network (simple digraph with sources and sinks) that also implements
 * a selection of optimization algorithms.
 */
class Network(EType): GenericDirectedGraph!(string, EType) {
protected:
    /// The user can't add vertices with the following names because they're used in the algorithms.
    static string[] reservedNames = ["a'", "z'", "a''", "z''"];
    EType flow; // Total network flow.

    /**
     * Allows bypassing the safety measures for reserved names. Meant for the algorithms
     * that actually use the reserved names.
     *
     * Params:
     *      name = Identifier for the new vertex
     */
    void addVertexWORestrictions(string name)
    {
        super.addVertex(name);
    }

    /**
     * Adds an arc between two vertices, while also enforcing a lot of safety measures
     * to mantain the properties of a Network.
     *
     * Params:
     *      source = Identifier for the source of the arc
     *      terminus = Identifier for the terminus of the arc
     *      weight = Weight/maximum flow possible of the arc
     *      minimum = Minimum flow restriction of the arc. Must be 0 for a Digraph's arc.
     *      flow = Initial flow of the arc. Must be 0 for a Digraph's arc.
     *
     * Throws: Exception in the following cases:
     *      - Weight is negative
     *      _ Weight is smaller than the minimum restriction
     *      - The minimum restriction is negative
     *      - The initial flow is negative or greater than the weight
     *      - Either the source or the terminus don't exist
     *      - There's already an arc between the given vertices
     */
    override void addArc(string source, string terminus, EType weight, EType minimum, EType flow)
    {
        import std.string: format;
        import std.exception: enforce;

        enforce(weight >= 0, format("Can't add an arc with negative weight. Weight given: %s.", weight));
        enforce(weight >= minimum, "Can't add an arc with an invalid restriction.");
        enforce(minimum >= 0, "Can't add an arc with an invalid restriction (negative minimum restriction).");
        enforce(flow <= weight, format("Can't add an arc with overflow. Flow: %s, maximum: %s.", flow, weight));
        enforce(flow >= 0, format("Can't add an arc with underflow. Flow: %s.", flow));

        auto sourceVertex = vertices.peek(source);
        auto terminusVertex = vertices.peek(terminus);

        enforce(sourceVertex !is null, "Tried to add an arc from an inexistent vertex.");
        enforce(terminusVertex !is null, "Tried to add an arc to an inexistent vertex.");
        enforce(!sourceVertex.outArcs.isThereAnArcTo(terminus), format("Tried to add a parallel arc between %s and %s.", source, terminus));

        super.addArc(source, terminus, weight, minimum, flow);
    }

    /**
     * Returns true if at least one arc restriction is found, false otherwise.
     */
    bool areThereRestrictionsInThisNetwork()
    {
        for(auto vertex = vertices.beginning; vertex !is null; vertex = vertex.next) {
            for(auto arc = vertex.begOutArcs; arc !is null; arc = arc.next) {
                if(arc.minimum > 0) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Iterates over all the vertices and resets the attributes that the Ford-Fulkerson
     * algorithm uses.
     */
    void resetFordFulkersonLabels()
    {
        for(auto vertex = vertices.beginning; vertex !is null; vertex = vertex.next) {
            vertex.touched = 0;
            vertex.ant = null;
            vertex.antArc = null;
        }
    }

    /**
     * An implementation of the Ford-Fulkerson algorithm. Finds the maximum possible
     * flow through the Network.
     *
     * It only works for networks that are already transformed. For the part that
     * actually enables working with restrictions on arcs and vertices, and multiple
     * sources and sinks, see FordFulkerson below.
     *
     * Params:
     *      sourceName = Identifier for the source
     *      sinkName = Identifier for the sink
     *      verbose = Whether to print each step of the optimization
     *
     * Returns: A Network object with the optimized flow.
     */
    auto FordFulkerson(string sourceName, string sinkName, bool verbose = false)
    {
        import std.algorithm.comparison: min;
        import std.stdio: write, writeln;
        import std.string: format;

        auto network = copy();
        bool chainFound = true;
        auto source = network.vertices.peek(sourceName);
        auto sink = network.vertices.peek(sinkName);
        // Possible states for the vertices.
        enum {unset = 0, touched = 1, examined = 2}

        // We start by resetting the labels of every vertex.
        network.resetFordFulkersonLabels();

        // We set the initial labels on the source.
        source.touched = touched;
        source.ant = source;
        source.antArc = null;
        source.opperation = true;
        source.chainCapacity = EType.max;

        // We look for chains.
        while(chainFound) {
            // Find a vertex to be examined.
            auto current = network.vertices.beginning;
            for(; current !is null; current = current.next) {
                if(current.touched == touched) {
                    break;
                }
            }

            // All vertex are examined. There isn't a chain.
            if(current is null) {
                chainFound = false;
                continue;
            }

            // Looking at all arcs that come out of this vertex.
            for(auto arc = current.begOutArcs; arc !is null; arc = arc.next) {
                // We can pass more flow through this arc.
                if(arc.terminus.touched == unset && arc.flow < arc.weight) {
                    arc.terminus.touched = touched;
                    arc.terminus.ant = current;
                    arc.terminus.antArc = arc;
                    arc.terminus.opperation = true;
                    arc.terminus.chainCapacity = min(current.chainCapacity, arc.weight - arc.flow);
                }
            }

            // Looking at all arcs that come into this vertex.
            for(auto arc = current.begInArcs; arc !is null; arc = arc.next) {
                // We can pass less flow through this arc.
                if(arc.source.touched == unset && arc.flow > arc.minimum) {
                    arc.source.touched = touched;
                    arc.source.ant = current;
                    arc.source.antArc = arc;
                    arc.source.opperation = false;
                    arc.source.chainCapacity = min(current.chainCapacity, arc.flow - arc.minimum);
                }
            }

            // We finished examining this vertex.
            current.touched = examined;

            // We update the network if we found a chain.
            if(sink.touched != unset) {
                for(auto updated = sink; updated != source; updated = updated.ant) {
                    if(updated.opperation) { // If we need to increment the flow.
                        updated.antArc.flow += sink.chainCapacity;
                        updated.inArcs.peek(updated.ant.name, updated.antArc.weight).flow += sink.chainCapacity;
                    } else { // If we need to decrement the flow.
                        updated.antArc.flow -= sink.chainCapacity;
                        updated.outArcs.peek(updated.ant.name, updated.antArc.weight).flow -= sink.chainCapacity;
                    }
                }

                network.flow += sink.chainCapacity;
                network.resetFordFulkersonLabels();

                if(verbose) {
                    writeln(format("An augmenting chain was found with capacity %s.", sink.chainCapacity));
                    writeln("Current state of the network after the latest changes:");
                    network.print();
                    write('\n');
                }

                // We set the initial labels on the source.
                source.touched = touched;
                source.ant = source;
                source.antArc = null;
                source.opperation = true;
                source.chainCapacity = EType.max;
            }
        }

        return network;
    }

    /**
     * Copies the flow from the arcs of another network to this network. They need
     * to have the same arcs, obviously.
     *
     * Params:
     *      network = Network to copy from
     */
    void copyFlow(Network!(EType) network)
    {
        for(auto vertex = vertices.beginning, otherVertex = network.vertices.beginning;
            vertex !is null; vertex = vertex.next, otherVertex = otherVertex.next) {
            for(auto arc = vertex.begOutArcs, otherArc = otherVertex.begOutArcs;
                arc !is null; arc = arc.next, otherArc = otherArc.next) {
                    arc.flow = otherArc.flow;
            }
        }
    }

    /**
     * Auxiliar function for FordFulkerson (see below). Checks if an initial flow
     * was found.
     *
     * Throws: Exception if a vertex with identifier a'' doesn't exist.
     */
    bool allArcsFull()
    {
        import std.exception: enforce;
        auto supersupersource = vertices.peek("a''");
        enforce(supersupersource !is null, "allArcsFull should only be used with Ford-Fulkerson. a'' doesn't exist in this network.");

        for(auto arc = supersupersource.begOutArcs; arc !is null; arc = arc.next) {
            if(arc.flow < arc.weight) {
                return false;
            }
        }

        return true;
    }
public:
    /**
     * Constructs an empty network with flow 0.
     */
    this()
    {
        super();
        flow = 0;
    }

    /**
     * Adds a vertex with the given identifier. Checks that the identifier isn't
     * reserved.
     *
     * Params:
     *      name = Identifier for the new vertex.
     *
     * Throws: Exception if a reserved name was given as a parameter.
     */
    override void addVertex(string name)
    {
        import std.algorithm: canFind;
        import std.exception: enforce;
        import std.string: format;
        enforce(!reservedNames.canFind(name), format("Can't use name %s. It's reserved.", name));
        super.addVertex(name);
    }

    /**
     * Adds an arc with minimum flow restriction 0, and initial flow 0.
     *
     * Params:
     *      source = Identifier of the source of the arc.
     *      terminus = Identifier of the terminus of the arc.
     *      weight = Weight/Maximum possible flow of the arc.
     */
    void addArc(string source, string terminus, EType weight)
    {
        addArc(source, terminus, weight, 0, 0);
    }

    /**
     * Adds an arc with initial flow 0.
     *
     * Params:
     *      source = Identifier of the source of the arc.
     *      terminus = Identifier of the terminus of the arc.
     *      weight = Weight/Maximum possible flow of the arc.
     *      minimum = Minimum flow that must pass through the arc.
     */
    void addArc(string source, string terminus, EType weight, EType minimum)
    {
        addArc(source, terminus, weight, minimum, 0);
    }

    /**
     * Deletes the contents of the network. It also sets the flow back to 0.
     */
    override void empty()
    {
        super.empty();
        flow = 0;
    }

    /**
     * Prints the contents of the network to the standard output. Includes every
     * attribute of the arcs.
     */
    override void print()
    {
        import std.stdio: write, writeln;
        import std.string: format;

        for(auto vertex = vertices.beginning; vertex !is null; vertex = vertex.next) {
            write(format("%s(deg+: %s; deg-: %s): ", vertex.name, vertex.outDegree, vertex.inDegree));
            for(auto arc = vertex.begOutArcs; arc !is null; arc = arc.next) {
                write(format("%s(f:%s, w:%s, r:%s) ", arc.opposite, arc.flow, arc.weight, arc.minimum));
            }
            write('\n');
        }

        writeln(format("The network has %s vertice(s) and %s arc(s). The current flow is: %s.", numVertices, numArcs, flow));
    }

    /**
     * Copies the contents of the network to a new instance.
     *
     * Returns: A new object with the same vertices and arcs.
     */
    override Network!(EType) copy()
    {
        auto networkCopy = new Network!(EType);

        // Adding every vertex.
        for(auto vertex = vertices.beginning; vertex !is null; vertex = vertex.next) {
            networkCopy.addVertexWORestrictions(vertex.name);
        }

        // Adding ever arc once.
        for(auto vertex = vertices.beginning; vertex !is null; vertex = vertex.next) {
            for(auto arc = vertex.begOutArcs; arc !is null; arc = arc.next) {
                networkCopy.addArc(vertex.name, arc.opposite, arc.weight, arc.minimum, arc.flow);
            }
        }

        networkCopy.flow = flow;

        return networkCopy;
    }

    /**
     * Sets every arc's flow to 0, as well as the total network flow.
     */
    void setTrivialFlow()
    {
        for(auto vertex = vertices.beginning; vertex !is null; vertex = vertex.next) {
            for(auto arc = vertex.begOutArcs; arc !is null; arc = arc.next) {
                arc.flow = 0;
            }
        }
        flow = 0;
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
     *
     * Returns: A new Network instance with the maximum flow.
     * Throws: Exception if any of the following happen:
     *      - sources or sinks are empty
     *      - Any source or sink doesn't exist
     *      - Any vertex has an invalid restriction
     *      - An initial flow wasn't found (if there are arc restrictions)
     */
    auto FordFulkerson(string[] sources, string[] sinks, EType[][string] vertexRestrictions = null, bool verbose = false)
    {
        import std.algorithm.comparison: min;
        import std.exception: enforce;

        import std.stdio: write, writeln;
        import std.string: format;

        enforce(sources.length > 0, "Cannot run Ford-Fulkerson with no sources.");
        enforce(sinks.length > 0, "Cannot run Ford-Fulkerson with no sinks.");

        auto network = copy();
        auto supersource = "a'";
        auto supersink = "z'";
        network.addVertexWORestrictions(supersource);
        network.addVertexWORestrictions(supersink);

        // Connecting every source and sink to the supersource and supersink.
        for(auto i = 0; i < sources.length; i++) {
            enforce(vertices.search(sources[i]), format("Couldn't find source %s.", sources[i]));
            network.addArc(supersource, sources[i], EType.max);
        }
        for(auto i = 0; i < sinks.length; i++) {
            enforce(vertices.search(sinks[i]), format("Couldn't find sink %s.", sinks[i]));
            network.addArc(sinks[i], supersink, EType.max);
        }

        if(vertexRestrictions !is null) {
            // We transform every vertex restriction.
            foreach(item; vertexRestrictions.byKeyValue()) {
                // item.value[0] is the maximum flow, item.value[1] is the minimum flow.
                enforce(item.value[0] >= item.value[1], format("Can't add a vertex with an invalid restriction. Weight: %s, restriction: %s.", item.value[0], item.value[1]));

                auto imgVertex = item.key ~ "'"; // New dummy vertex.
                network.addVertex(imgVertex);

                // Moving every arc to the dummy vertex.
                for(auto arc = network.vertices.peek(item.key).begOutArcs; arc !is null; arc = arc.next) {
                    network.addArc(imgVertex, arc.opposite, arc.weight, arc.minimum);
                    network.removeArc(arc.source.name, arc.opposite, arc.weight);
                }

                network.addArc(item.key, imgVertex, item.value[0], item.value[1]);
            }

            if(verbose) {
                writeln("Network after transforming the vertices' restrictions:");
                network.print();
                write('\n');
            }
        }

        if(network.areThereRestrictionsInThisNetwork()) {
            auto initFlowNetwork = network.copy();
            auto supersupersource = "a''";
            auto supersupersink = "z''";
            initFlowNetwork.addVertexWORestrictions(supersupersource);
            initFlowNetwork.addVertexWORestrictions(supersupersink);
            initFlowNetwork.addArc(supersource, supersink, EType.max);
            initFlowNetwork.addArc(supersink, supersource, EType.max);

            EType minFlow;
            for(auto vertex = initFlowNetwork.vertices.beginning; vertex !is null; vertex = vertex.next) {
                minFlow = 0;
                // Adding up every arc restriction.
                for(auto arc = vertex.begOutArcs; arc !is null; arc = arc.next) {
                    minFlow += arc.minimum;
                    if(arc.minimum > 0) {
                        arc.weight -= arc.minimum;
                        arc.minimum = 0;
                    }
                }
                if(minFlow > 0) {
                    initFlowNetwork.addArc(vertex.name, supersupersink, minFlow);
                }

                minFlow = 0;
                // Adding up every arc restriction.
                for(auto arc = vertex.begInArcs; arc !is null; arc = arc.next) {
                    minFlow += arc.minimum;
                    if(arc.minimum > 0) {
                        arc.weight -= arc.minimum;
                        arc.minimum = 0;
                    }
                }
                if(minFlow > 0) {
                    initFlowNetwork.addArc(supersupersource, vertex.name, minFlow);
                }
            }

            initFlowNetwork.setTrivialFlow();
            initFlowNetwork = initFlowNetwork.FordFulkerson(supersupersource, supersupersink, verbose);
            enforce(initFlowNetwork.allArcsFull(), "The network has no solution with the restrictions given.");

            if(verbose) {
                writeln("Network after finding an initial flow:");
                initFlowNetwork.print();
                write('\n');
            }

            network.copyFlow(initFlowNetwork);
            network.flow = initFlowNetwork.vertices.peek(supersink).begOutArcs.flow;

            // We start examining every arc that enters the supersupersink.
            for(auto initArc = initFlowNetwork.vertices.peek(supersupersink).begInArcs; initArc !is null; initArc = initArc.next) {
                // We get the vertex in 'network' which arcs we need to modify.
                auto origVertex = network.vertices.peek(initArc.opposite);
                // We distribute the arc's flow between all of the origVertex's arcs with restrictions.
                for(auto origArc = origVertex.begOutArcs; initArc.flow > 0; origArc = origArc.next) {
                    // Beginning again in case there's additional flow to be distributed.
                    if(origArc is null) origArc = origVertex.begOutArcs;
                    if(origArc.minimum > 0 && origArc.flow < origArc.weight) {
                        auto change = min(origArc.minimum, initArc.flow, origArc.weight - origArc.flow);
                        origArc.flow += change;
                        initArc.flow -= change;
                    }
                }
            }
            // We continue examining every arc that exits the supersupersource.
            for(auto initArc = initFlowNetwork.vertices.peek(supersupersource).begOutArcs; initArc !is null; initArc = initArc.next) {
                // We get the vertex in 'network' which arcs we need to modify.
                auto origVertex = network.vertices.peek(initArc.opposite);
                // We distribute the arc's flow between all of the origVertex's arcs with restrictions.
                for(auto origArc = origVertex.begInArcs; initArc.flow > 0; origArc = origArc.next) {
                    // Beginning again in case there's additional flow to be distributed.
                    if(origArc is null) origArc = origVertex.begInArcs;
                    if(origArc.minimum > 0 && origArc.flow < origArc.weight) {
                        auto change = min(origArc.minimum, initArc.flow, origArc.weight - origArc.flow);
                        origArc.flow += change;
                        initArc.flow -= change;
                    }
                }
            }

            if(verbose) {
                writeln("Network after transforming back from the additional arcs:");
                network.print();
                write('\n');
            }
        } else {
            network.setTrivialFlow();
        }

        network = network.FordFulkerson(supersource, supersink, verbose);

        if(verbose) {
            writeln("Network after finding the maximum flow possible:");
            network.print();
            write('\n');
        }

        if(vertexRestrictions !is null) {
            // Erasing every dummy vertex and moving back all the necessary arcs.
            foreach(item; vertexRestrictions.byKeyValue()) {
                auto imgVertex = item.key ~ "'";
                for(auto arc = network.vertices.peek(imgVertex).begOutArcs; arc !is null; arc = arc.next) {
                    network.addArc(item.key, arc.opposite, arc.weight, arc.minimum, arc.flow);
                }
                network.removeVertex(imgVertex);
            }
        }

        network.removeVertex(supersource);
        network.removeVertex(supersink);

        if(verbose) {
            writeln("Final network (without extra vertices nor extra arcs):");
            network.print();
            write('\n');
        }

        return network;
    }

    /**
     * Returns the current flow passing through the network.
     */
    auto currentFlow() const @property
    {
        return flow;
    }

    /**
     * Returns the list of reserved names for vertices.
     */
    auto forbiddenNames() const @property
    {
        return reservedNames;
    }
}
