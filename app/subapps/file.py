import json
import networkx as nx

def save_graph(graph, file_id):
    graph_data = nx.node_link_data(graph)
    with open("./data/{}.json".format(file_id), 'w') as outfile:
        json.dump(graph_data, outfile)
    return "./data/{}.json".format(file_id)

def load_graph(file_id):
    with open("./data/{}-final.txt".format(file_id), 'r') as f:
        isGraph = True
        header = f.readline().split()[0]
        graph = nx.Graph()
        info = ''
        if header == 'graph':
            graph = nx.Graph()
        elif header == 'digraph':
            graph = nx.DiGraph()
        else: # header == 'exception'. An exception happened over in D land.
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

            if item.split()[0] == 'extra':
                info = f.readline()

    return graph, isGraph, info

def load_digraph(file_id):
    with open("./data/{}-final.txt".format(file_id), 'r') as f:
        isGraph = True
        header = f.readline().split()[0]
        graph = nx.DiGraph()
        info = ''
        if header != 'digraph': # header == 'exception'. An exception ocurred over in D land.
            isGraph = False
            graph = f.readline()

        if isGraph:
            f.readline() # Skipping the vertex header.
            item = f.readline().split() # First vertex.
            while item[0] != 'edges':
                graph.add_node(item[0], name=item[1])
                item = f.readline().split()

            item = f.readline() # Reading the next line after the edges header.
            while item.split()[0] != 'extra' and item.split()[0] != 'end':
                source, terminus, weight = item.split()
                graph.add_edge(source, terminus, weight=int(weight))
                item = f.readline()

            if item.split()[0] == 'extra':
                info = f.readline()

    return graph, isGraph, info

def load_network(file_id):
    with open("./data/{}-final.txt".format(file_id), 'r') as f:
        isGraph = True
        header = f.readline().split()[0]
        graph = nx.DiGraph()
        info = ''
        if header == 'exception':
            isGraph = False
            graph = f.readline()

        if isGraph:
            f.readline() # Skipping the vertex header.
            item = f.readline().split() # First vertex.
            while item[0] != 'edges':
                if len(item) == 4: # Vertex.
                    name, type, _, _ = item
                    graph.add_node(name, type=type)
                elif len(item) == 6: # Vertex with restrictions.
                    name, type, _, min, max, _ = item
                    graph.add_node(name, type=type, min_flow=int(min), max_flow=int(max))
                elif len(item) == 5: # Vertex with production or demand.
                    name, type, _, _, production = item
                    graph.add_node(name, type=type, flow=int(production))

                item = f.readline().split()

            item = f.readline() # Reading the next line after the edges header.
            while item.split()[0] != 'extra' and item.split()[0] != 'end':
                source, terminus, capacity, restriction, flow, cost = item.split()
                graph.add_edge(source, terminus, weight=int(capacity), restriction=int(restriction), flow=int(flow), cost=int(cost), info='r:{}, f:{}, q:{}, c:{}'.format(restriction, flow, capacity, cost))
                item = f.readline()

            if item.split()[0] == 'extra':
                info = f.readline()

    return graph, isGraph, info
