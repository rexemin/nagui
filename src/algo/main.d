import std.stdio: write, writeln;
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
        tree.saveToFile(id);
    } else if(algorithm == "prim") {
        auto tree = graph.prim(hasTree, treeWeight);
        tree.saveToFile(id);
    }
}
