import std.stdio: write, writeln;
import std.string: format;

import datastruct.undirected.graph;

void main(string[] args)
{
    // auto outputFile = File("../../data/data.txt", "w");
    // args = args[1..$];
    // foreach(arg; args) {
        // outputFile.writeln(arg);
    // }

    auto file_path = args[1];
    auto algorithm = args[2];

    auto graph = new Graph!(string, int)();
    // graph = graph.load_from_json(file_path);

    if(algorithm == "fleury") {
        writeln(algorithm);
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
