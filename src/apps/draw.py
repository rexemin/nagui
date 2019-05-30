import plotly.offline as py
import plotly.graph_objs as go

import numpy as np
import networkx as nx

def get_edges_coordinates(graph, layout):
    coordinates = [[], []]

    for edge in graph.edges():
        coordinates[0] += [layout[edge[0]][0], layout[edge[1]][0], None]
        coordinates[1] += [layout[edge[0]][1], layout[edge[1]][1], None]

    return coordinates

def update_trace(current_trace, current_graph):
    graph_layout = nx.layout.kamada_kawai_layout(current_graph, weight=None)
    edges_coordinates = get_edges_coordinates(current_graph, graph_layout)
    vertices_coordinates = np.array(list(graph_layout.values())).T

    traces = [
        go.Scatter(
            x=edges_coordinates[0],
            y=edges_coordinates[1],
            mode='lines',
            line={
                'shape': 'spline',
                'smoothing': 1.3,
                'color': 'rgb(30, 144, 255)',
                'width': 5
            },
            hoverinfo='none',
            name='Edges'
        ),
        go.Scatter(
            x=vertices_coordinates[0],
            y=vertices_coordinates[1],
            mode='markers+text',
            marker={
                'symbol': 'circle',
                'size': 50,
                'color': 'black'
            },
            text=[v for v in current_graph.nodes()],
            textfont={
                'size': 28,
                'color': 'white'
            },
            opacity=0.8,
            name='Vertices',
            hoverinfo='text'
        ),
    ]

    new_trace = {
        'data': traces,
        'layout': current_trace['layout']
    }

    return new_trace
