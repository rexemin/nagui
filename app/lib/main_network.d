import std.stdio: write, writeln, File;
import std.string: format;

import datastruct.directed.network;

void main(string[] args)
{
    import std.conv: parse;

    auto filePath = args[1];
    auto id = args[2];
    auto algorithm = args[3];
    auto F = parse!long(args[4]);

    string[] sources, sinks;
    long[][string] vertexRestrictions;
    long[string] productions;
    auto network = new Network!(long)();
    network = network.loadFromNxJSON(filePath, sources, sinks, vertexRestrictions, productions);
    string outPath = format("./data/%s-final.txt", id);

    try{
        if(algorithm == "ford") {
            network = network.fordFulkerson(sources, sinks, vertexRestrictions, false);
            auto info = [format("Flow: %s. Cost: %s.", network.flow, network.cost)];
            network.saveToFile(outPath, sources, sinks, vertexRestrictions, productions, info);
        } else if(algorithm == "mincycle") {
            network = network.minimumCostFlow(F, sources, sinks, vertexRestrictions, false);
            auto info = [format("Flow: %s. Cost: %s.", network.flow, network.cost)];
            network.saveToFile(outPath, sources, sinks, vertexRestrictions, productions, info);
        } else if(algorithm == "minpaths") {
            bool solutionFound;
            network = network.minimumCostFlowWithShortestPaths(F, solutionFound, sources, sinks, vertexRestrictions, false);
            auto info = [format("Flow: %s. Cost: %s.", network.flow, network.cost)];
            network.saveToFile(outPath, sources, sinks, vertexRestrictions, productions, info);
        } else if(algorithm == "simplex") {
            auto productionsCopy = productions.dup;
            network = network.simplex(productionsCopy);
            auto info = [format("Cost: %s.", network.cost)];
            network.saveToFile(outPath, sources, sinks, vertexRestrictions, productions, info);
        }
    } catch(Exception e) {
        auto outputFile = File(outPath, "w");
        // Header.
        outputFile.writeln("exception");
        outputFile.writeln(e.msg);
    }
}
