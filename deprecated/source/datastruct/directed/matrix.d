module datastruct.directed.matrix;

struct FWNode(VType, EType) {
    VType ant;
    EType dist;
    bool touched;
}

/*
class FWMatrix(VType, EType) {
    package int numberNodes;
    package FWNode[VType][VType] nodes;

    this(int numberNodes)
    {
        this.numberNodes = numberNodes;
    }

    public void print() const
    {
        import std.stdio: write;
        import string: format;

        // Header.
        write('\t');
        foreach(item: nodes.byKeyValue()) {
            write(format("%s\t", item.key));
        }
        write('\n');

        // Each row.
        foreach(row: nodes.byKeyValue()) {
            write(format("%s\t", row.key));
            for(col: row.byKeyValue()) {
                if(col.value.touched) {
                    write(format("%s(%s)\t", col.value.ant, col.value.dist));
                } else {
                    write("-(inf)\t");
                }
            }
        }
    }

    public VType[] retrievePath(VType start, VType end, ref EType length, ref bool pathFound)
    {
        import std.exception: enforce;
        enforce(start in this.nodes && end in this.nodes, "Tried to find a path to a vertex not in the digraph.");

        VType[] path;

        if(!this.nodes[start][end].touched) {
            length = EType.max;
            pathFound = false;
            return path;
        }

        length = this.nodes[start][end].dist;
        path ~= end;

        while() {

        }
    }

    void printAllPaths()
    {

    }
}
*/
