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

    bool cycleFound;
    long[string] shortestPaths;
    string[string] previous;
    string outPath = format("./data/%s-final.txt", id);

    try{
        if(algorithm == "dijkstra") {
            auto tree = digraph.dijkstra(start, cycleFound, shortestPaths, previous);
            if(cycleFound) {
                tree.saveToFile(outPath, ["A negative cycle was found."]);
            } else {
                tree.saveToFile(outPath);
            }
        } else if(algorithm == "floyd") {
            auto dict = digraph.floyd();
            auto trees = digraph.getTreesFromDict(dict);
            digraph.saveFloydToFile(outPath, trees);
        }
    } catch(Exception e) {
        auto outputFile = File(outPath, "w");
        // Header.
        outputFile.writeln("exception");
        outputFile.writeln(e.msg);
    }
}
