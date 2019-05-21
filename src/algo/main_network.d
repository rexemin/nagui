import std.stdio: write, writeln, File;
import std.string: format;

import datastruct.directed.network;

void main(string[] args)
{
    auto filePath = args[1];
    auto id = args[2];
    auto algorithm = args[3];

    string[] sources, sinks;
    long[][string] vertexRestrictions;
    long[string] productions;
    auto network = new Network!(long)();
    network = network.loadFromNxJSON(filePath, sources, sinks, vertexRestrictions, productions);
    network.print();
    writeln(sources);
    writeln(sinks);
    writeln(vertexRestrictions);
    writeln(productions);

    network.saveToFile(id, sources, sinks, vertexRestrictions, productions);

    try{
        if(algorithm == "ford") {
            writeln("To be implemented.");
        } else if(algorithm == "mincycle") {
            writeln("To be implemented.");
        } else if(algorithm == "minpaths") {
            writeln("To be implemented.");
        } else if(algorithm == "simplex") {
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
