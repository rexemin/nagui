import std.stdio: write, writeln, File;
import std.string: format;

import datastruct.undirected.graph;

void main(string[] args)
{
    auto filePath = args[1];
    auto id = args[2];
    auto algorithm = args[3];
    bool isConnected, hasTree;
    long treeWeight;

    auto graph = new Graph!(string, long)();
    graph = graph.loadFromNxJSON(filePath);
    graph.print();

    try{
        if(algorithm == "fleury") {
            auto circuit = graph.fleury(isConnected);
            circuit.saveToFile(id);
        } else if(algorithm == "bfs") {
            auto tree = graph.bfs(isConnected);
            tree.saveToFile(id);
        } else if(algorithm == "idfs") {
            auto tree = graph.idfs(isConnected);
            tree.saveToFile(id);
        } else if(algorithm == "rdfs") {
            auto tree = graph.rdfs(isConnected);
            tree.saveToFile(id);
        } else if(algorithm == "kruskal") {
            auto tree = graph.kruskal(hasTree, treeWeight);
            auto info = format("The minimum tree has weight: %s", treeWeight);
            tree.saveToFile(id, [info]);
        } else if(algorithm == "prim") {
            auto tree = graph.prim(hasTree, treeWeight);
            auto info = format("The minimum tree has weight: %s", treeWeight);
            tree.saveToFile(id, [info]);
        }
    } catch(Exception e) {
        string outPath = format("./../data/%s-final.txt", id);
        auto outputFile = File(outPath, "w");
        // Header.
        outputFile.writeln("exception");
        outputFile.writeln(e.msg);
    }
}
