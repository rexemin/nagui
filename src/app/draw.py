import numpy as np

import plotly.offline as py
import plotly.graph_objs as go

def find_vertex_id(graph, vertex):
    for v in graph.vs:
        if v.attributes()['name'] == vertex:
            return v.index

def get_edges_coordinates(graph, layout):
    coordinates = [[], []]

    for e in graph.es:
        e_v = e.tuple
        coordinates[0] += [layout[e_v[0]][0], layout[e_v[1]][0], None]
        coordinates[1] += [layout[e_v[0]][1], layout[e_v[1]][1], None]

    return coordinates

def update_trace(current_trace, current_graph):
    graph_layout = np.array(current_graph.layout('kamada_kawai'))
    edges_coordinates = get_edges_coordinates(current_graph, graph_layout)

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
            x=graph_layout.T[0],
            y=graph_layout.T[1],
            mode='markers+text',
            marker={
                'symbol': 'circle',
                'size': 50,
                'color': 'black'
            },
            text=[v['name'] for v in current_graph.vs],
            textfont={
                'size': 28,
                'color': 'white'
            },
            opacity=0.8,
            name='Vertices'
        ),
    ]

    new_trace = {
        'data': traces,
        'layout': current_trace['layout']
    }

    return new_trace
