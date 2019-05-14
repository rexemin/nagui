import json
import networkx as nx

def save_graph(graph, file_id):
    graph_data = nx.node_link_data(graph)
    with open("../../data/{}.json".format(file_id), 'w') as outfile:
        json.dump(graph_data, outfile)
    return "../../data/{}.json".format(file_id)

def load_graph(file_id):
    with open("../../data/{}-final.txt".format(file_id), 'r') as f:
        isGraph = True
        header = f.readline().split()[0]
        graph = nx.Graph()
        if header == 'graph':
            graph = nx.Graph()
        elif header == 'digraph':
            graph = nx.DiGraph()
        else: # header == 'exception'. An exception ocurred over in D land.
            isGraph = False
            graph = f.readline()

        if isGraph:
            f.readline() # Skipping the vertex header.
            item = f.readline().split()[0] # First vertex.
            while item != 'edges':
                graph.add_node(item)
                item = f.readline().split()[0]

            item = f.readline() # Reading the next line after the edges header.
            while item.split()[0] != 'extra' and item.split()[0] != 'end':
                source, terminus, weight = item.split()
                graph.add_edge(source, terminus, weight=int(weight))
                item = f.readline()

    return graph, isGraph

# graph = load_graph(0)
# print(nx.classes.function.info(graph))
# print(nx.node_link_data(graph))
