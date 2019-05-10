import json
import networkx as nx

def save_graph(graph, file_id):
    graph_data = nx.node_link_data(graph)
    with open("../../data/{}.json".format(file_id), 'w') as outfile:
        json.dump(graph_data, outfile)
