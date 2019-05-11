import json
import networkx as nx

def save_graph(graph, file_id):
    graph_data = nx.node_link_data(graph)
    with open("../../data/{}.json".format(file_id), 'w') as outfile:
        json.dump(graph_data, outfile)
    return "../../data/{}.json".format(file_id)

def load_graph(file_id):
    with open("../../data/{}-final.json".format(file_id), 'w') as outfile:
        pass
