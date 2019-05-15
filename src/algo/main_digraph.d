import std.stdio: write, writeln, File;
import std.string: format;

import datastruct.directed.digraph;

void main(string[] args)
{
    auto filePath = args[1];
    auto id = args[2];
    auto algorithm = args[3];
    auto start = args[4];

    auto digraph = new Digraph!(string, long)();
    digraph = digraph.loadFromNxJSON(filePath);
    digraph.print();

    bool cycleFound;
    long[string] shortestPaths;
    string[string] previous;

    try{
        if(algorithm == "dijkstra") {
            auto tree = digraph.dijkstra(start, cycleFound, shortestPaths, previous);
            if(cycleFound) {
                tree.saveToFile(id, ["A negative cycle was found."]);
            } else {
                tree.saveToFile(id);
            }
        } else if(algorithm == "floyd") {
            writeln("To be implemented.");
        }
    } catch(Exception e) {
        string outPath = format("../../data/%s-final.txt", id);
        auto outputFile = File(outPath, "w");
        // Header.
        outputFile.writeln("exception");
        outputFile.writeln(e.msg);
    }
}
