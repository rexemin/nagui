import std.stdio: write, writeln;
import std.string: format;

import datastruct.undirected.graph;

void main(string[] args)
{
    auto filePath = args[1];
    auto algorithm = args[2];

    auto graph = new Graph!(string, long)();
    graph = graph.loadFromNxJSON(filePath);
    graph.print();

    if(algorithm == "fleury") {
        // writeln(algorithm);
        bool ia;
        auto circuit = graph.fleury(ia);
        foreach(c; circuit) {
            writeln(c);
        }
    } else if(algorithm == "bfs") {
        writeln(algorithm);
    } else if(algorithm == "idfs") {
        writeln(algorithm);
    } else if(algorithm == "rdfs") {
        writeln(algorithm);
    } else if(algorithm == "kruskal") {
        writeln(algorithm);
    } else if(algorithm == "prim") {
        writeln(algorithm);
    }
}
