import std.stdio;
import std.string: format;

void main(string[] args)
{
    auto outputFile = File("../../data/data.txt", "w");
    args = args[1..$];
    foreach(arg; args) {
        outputFile.writeln(arg);
    }
}
