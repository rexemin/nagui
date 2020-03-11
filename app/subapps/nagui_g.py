# Plotly/Dash for the GUI and visualization.
import dash
import dash_core_components as dcc
import dash_html_components as html
import dash_cytoscape as cyto
import dash_bootstrap_components as dbc
from dash.dependencies import Input, Output, State

from nagui import app

import numpy as np
import networkx as nx

# draw and file for the wacky stuff with D.
import subapps.file as file
import subprocess as sbp

#--- Global variables

vis_height = '750px'
current_graph = nx.Graph()
original_graph = nx.Graph()
file_id = 0
info = ''

#--- End of global variables

#--- GUI

# external_stylesheets = [dbc.themes.BOOTSTRAP] #['https://codepen.io/chriddyp/pen/bWLwgP.css']
# app = dash.Dash(__name__, external_stylesheets=external_stylesheets)

#app.
layout = html.Div([
    dbc.Container([
        dbc.Row([
            dbc.Col([
                html.H1('Graphs', className='m-4', id='header-graph'),
            ], width=3),
            dbc.Col([
                dcc.Link('Go back', href='/', className='btn btn-primary m-2'),
            ], width=2)
        ], justify='around', align='center')
    ]),

    dbc.Container([
        dbc.Row([
            dbc.Col([
                dbc.Row([
                    dbc.Col([
                        html.H5('Add new vertex:'),
                    ], width=3),
                    dbc.Col([
                        dbc.Input(id='vertex-graph', type='text', className='mx-1 my-1'),
                    ], width=6),
                    dbc.Col([
                        dbc.Button('Add vertex', color='primary', id='btn-vertex-graph', className='my-2'),
                    ], width=3),
                ], justify='around', align='center', className='p-1'),
                html.Br(),
                dbc.Row([
                    dbc.Col([
                        html.H5('Add new edge:'),
                    ], width=3),
                    dbc.Col([
                        dbc.Input(id='source-graph', type='text', className='mx-1 my-1'),
                    ], width=4),
                    dbc.Col([
                        html.H6('to'),
                    ], width=1),
                    dbc.Col([
                        dbc.Input(id='terminus-graph', type='text', className='mx-1 my-1'),
                    ], width=4),
                ], justify='around', align='center', className='p-1'),
                dbc.Row([
                    dbc.Col([
                        html.H6('With weight: '),
                    ], width=3),
                    dbc.Col([
                        dbc.Input(id='weight-graph', type='number', className='mx-1 my-1'),
                    ], width=6),
                    dbc.Col([
                        dbc.Button('Add edge', color='primary', id='btn-edge-graph', className='my-1')
                    ], width=3),
                ], justify='around', align='center'),
                html.Br(),
                dbc.Row([
                    dbc.Col([
                        html.H5('Remove vertex:'),
                    ], width=3),
                    dbc.Col([
                        dbc.Input(id='rm-vertex-graph', type='text', className='mx-1 my-1'),
                    ], width=6),
                    dbc.Col([
                        dbc.Button('Remove vertex', color='primary', id='btn-rm-vertex-graph', className='my-2'),
                    ], width=3),
                ], justify='around', align='center', className='p-1'),
                html.Br(),
                dbc.Row([
                    dbc.Col([
                        html.H5('Remove edge:'),
                    ], width=2),
                    dbc.Col([
                        dbc.Input(id='rm-source-graph', type='text', className='mx-1 my-1'),
                    ], width=3),
                    dbc.Col([
                        html.H6('to'),
                    ], width=1),
                    dbc.Col([
                        dbc.Input(id='rm-terminus-graph', type='text', className='mx-1 my-1'),
                    ], width=3),
                    dbc.Col([
                        dbc.Button('Remove edge', color='primary', id='btn-rm-edge-graph', className='my-2'),
                    ], width=3),
                ], justify='around', align='center', className='p-1'),
                html.Br(),
                dbc.Row([
                    dbc.Button('Empty graph', color='warning', id='btn-empty-graph', className='mx-2'),
                    # dbc.Button('Load graph', color='primary', id='btn-load-graph', className='mx-2'),
                    # dbc.Button('Save graph', color='primary', id='btn-save-graph', className='mx-2')
                ], justify='center', className='m-4')
            ], width=3),
            dbc.Col([
                dbc.Row([
                    dbc.Col([
                        html.H4('The graph has 0 node(s) and 0 edge(s).', id='info-graph', className='mx-3'),
                    ], width=4),
                    dbc.Col([
                        html.H3('', id='additional-info-graph', className='mx-3')
                    ], width=4),
                    dbc.Col([
                        dcc.Dropdown(
                            id='drop-algo-graph',
                            options=[
                                {'label': 'Fleury', 'value': 'fleury'},
                                {'label': 'Iterative DFS', 'value': 'idfs'},
                                {'label': 'Recursive DFS', 'value': 'rdfs'},
                                {'label': 'BFS', 'value': 'bfs'},
                                {'label': 'Kruskal', 'value': 'kruskal'},
                                {'label': 'Prim', 'value': 'prim'},
                            ],
                            clearable=False,
                            value='fleury'
                        ),
                    ], width=2),
                    dbc.Col([
                        # dbc.Button('Previous step', color='info', id='btn-prev-graph', className='mx-2'),
                        # dbc.Button('Next step', color='info', id='btn-next-graph', className='mx-2'),
                        dbc.Button('Run', color='info', id='btn-run-graph', className='mx-2'),
                        dbc.Button('Reset', color='warning', id='btn-reset-graph', className='mx-2'),
                    ], width=2)
                ], justify='between'),
                cyto.Cytoscape(
                    id='graph',
                    layout={
                        'name': 'cose'
                    },
                    style={
                        'width': '100%',
                        'height': '750px'
                    },
                    stylesheet=[
                        {
                            'selector': 'node',
                            'style': {
                                'label': 'data(id)'
                            }
                        },
                        {
                            'selector': 'edge',
                            'style': {
                                'label': 'data(weight)',
                                'curve-style': 'bezier',
                            }
                        },
                    ],
                    elements=[]
                )
            ], width=9)
        ])
    ], fluid=True),
])

#--- End of GUI

#--- Callbacks

"""
Updating the graph every time a vertex or an edge are added/removed.
"""
@app.callback(
    Output(component_id='graph', component_property='elements'),
    [Input(component_id='btn-vertex-graph', component_property='n_clicks_timestamp'),
     Input(component_id='btn-edge-graph', component_property='n_clicks_timestamp'),
     Input(component_id='btn-rm-vertex-graph', component_property='n_clicks_timestamp'),
     Input(component_id='btn-rm-edge-graph', component_property='n_clicks_timestamp'),
     Input(component_id='btn-run-graph', component_property='n_clicks_timestamp'),
     Input(component_id='btn-reset-graph', component_property='n_clicks_timestamp'),
     Input(component_id='btn-empty-graph', component_property='n_clicks_timestamp')],
    [State(component_id='vertex-graph', component_property='value'),
     State(component_id='source-graph', component_property='value'),
     State(component_id='terminus-graph', component_property='value'),
     State(component_id='rm-vertex-graph', component_property='value'),
     State(component_id='rm-source-graph', component_property='value'),
     State(component_id='rm-terminus-graph', component_property='value'),
     State(component_id='weight-graph', component_property='value'),
     State('drop-algo-graph', 'value'),
     State('graph', 'elements')]
)
def update_graph(btn_vertex, btn_edge, btn_rm_v, btn_rm_e, btn_run, btn_reset, btn_empty, vertex_value, source, terminus,
    rm_vertex, rm_source, rm_terminus, weight, algorithm, elements):
    global current_graph
    global file_id
    global original_graph
    global info

    info = ''
    buttons = np.array([btn if btn is not None else 0 for btn in (btn_vertex, btn_edge, btn_rm_v, btn_rm_e, btn_run, btn_reset, btn_empty)])
    btn_pressed = np.argmax(buttons)

    if btn_vertex is not None and btn_pressed == 0 and vertex_value != "":
        if not current_graph.has_node(vertex_value):
            current_graph.add_node(vertex_value)
            elements = nx.readwrite.json_graph.cytoscape_data(current_graph)
            elements = elements['elements']['nodes'] + elements['elements']['edges']
        else:
            info = 'Vertex {} is already on the graph.'.format(vertex_value)
    elif btn_edge is not None and btn_pressed == 1 and source != "" and terminus != "" and weight is not None:
        if current_graph.has_node(source) and current_graph.has_node(terminus):
            current_graph.add_edge(source, terminus, weight=weight)
            elements = nx.readwrite.json_graph.cytoscape_data(current_graph)
            elements = elements['elements']['nodes'] + elements['elements']['edges']
        elif not current_graph.has_node(source) and current_graph.has_node(terminus):
            info = 'Vertex {} is not on the graph.'.format(source)
        elif current_graph.has_node(source) and not current_graph.has_node(terminus):
            info = 'Vertex {} is not on the graph.'.format(terminus)
        else:
            info = 'Vertices {} and {} are not on the graph.'.format(source, terminus)
    elif btn_rm_v is not None and btn_pressed == 2 and rm_vertex != "":
        if current_graph.has_node(rm_vertex):
            current_graph.remove_node(rm_vertex)
            elements = nx.readwrite.json_graph.cytoscape_data(current_graph)
            elements = elements['elements']['nodes'] + elements['elements']['edges']
        else:
            info = 'Vertex {} is not on the graph.'.format(rm_vertex)
    elif btn_rm_e is not None and btn_pressed == 3 and rm_source != "" and rm_terminus != "":
        if current_graph.has_node(rm_source) and current_graph.has_node(rm_terminus) and current_graph.has_edge(rm_source, rm_terminus):
            current_graph.remove_edge(rm_source, rm_terminus)
            elements = nx.readwrite.json_graph.cytoscape_data(current_graph)
            elements = elements['elements']['nodes'] + elements['elements']['edges']
        elif not current_graph.has_node(rm_source) and current_graph.has_node(rm_terminus):
            info = 'Vertex {} is not on the graph.'.format(rm_source)
        elif current_graph.has_node(rm_source) and not current_graph.has_node(rm_terminus):
            info = 'Vertex {} is not on the graph.'.format(rm_terminus)
        elif not current_graph.has_node(rm_source) and not current_graph.has_node(rm_terminus):
            info = 'Vertices {} and {} are not on the graph.'.format(rm_source, rm_terminus)
        else:
            info = "There isn't an edge between vertices {} and {}.".format(rm_source, rm_terminus)
    elif btn_run is not None and btn_pressed == 4:
        file_path = file.save_graph(current_graph, file_id)
        original_graph = current_graph
        sbp.run(["./lib/bin/graph.out", file_path, str(file_id), algorithm])
        result, is_a_graph, info = file.load_graph(file_id)
        if is_a_graph:
            current_graph = result
            file_id += 1
        else:
            info = result
        elements = nx.readwrite.json_graph.cytoscape_data(current_graph)
        elements = elements['elements']['nodes'] + elements['elements']['edges']
    elif btn_reset is not None and btn_pressed == 5:
        current_graph = original_graph
        elements = nx.readwrite.json_graph.cytoscape_data(current_graph)
        elements = elements['elements']['nodes'] + elements['elements']['edges']
        if file_id > 1:
            file_id -= 1
    elif btn_empty is not None and btn_pressed == 6:
        current_graph.clear()
        elements = nx.readwrite.json_graph.cytoscape_data(current_graph)
        elements = elements['elements']['nodes'] + elements['elements']['edges']
    return elements

"""
Displaying additional information,
"""
@app.callback(
    Output('additional-info-graph', 'children'),
    [Input('graph', 'elements')]
)
def update_additional_info(graph):
    global info
    return info

"""
Changing the graph's stylesheet everytime there's a change between types.
"""
@app.callback(
    Output('graph', 'stylesheet'),
    [Input('graph', 'elements')]
)
def update_graph_stylesheet(graph):
    global current_graph
    if type(current_graph) == nx.classes.graph.Graph:
        return [
            {
                'selector': 'node',
                'style': {
                    'label': 'data(id)'
                }
            },
            {
                'selector': 'edge',
                'style': {
                    'label': 'data(weight)',
                    'curve-style': 'bezier',
                }
            }
        ]
    else:
        return [
            {
                'selector': 'node',
                'style': {
                    'label': 'data(id)'
                }
            },
            {
                'selector': 'edge',
                'style': {
                    'label': 'data(weight)',
                    'curve-style': 'bezier',
                    'target-arrow-shape': 'vee'
                }
            }
        ]

"""
Changing the information displayed at the top of the page every time the graph
is changed.
"""
@app.callback(
    Output(component_id='info-graph', component_property='children'),
    [Input(component_id='graph', component_property='elements')]
)
def update_graph_info(graph):
    return "The graph has {} node(s) and {} edge(s)".format(current_graph.number_of_nodes(), current_graph.number_of_edges())

"""
Input/Output of the current graph to/from text files.
"""
# @app.callback(
#     Output(component_id='header-graph', component_property='children'),
#    # [Input(component_id='btn-load-graph', component_property='n_clicks'),
#     [Input(component_id='btn-run-graph', component_property='n_clicks')],
#     [State('drop-algo-graph', 'value')]
# )
# def run_algorithm(n_clicks, algorithm):
#     global file_id
#     global original_graph
#     if n_clicks is not None and n_clicks > 0:
#         file_path = file.save_graph(current_graph, file_id)
#         original_graph = current_graph
#         sbp.run(["../algo/graph.out", file_path, algorithm])
#         temp = file.load_graph(file_id)
#         print(temp)
#         # elements = nx.readwrite.json_graph.cytoscape_data(current_graph)
#         # elements = elements['elements']['nodes'] + elements['elements']['edges']
#         # file_id += 1
#     return "Graphs"

"""
Resetting the Inputs every time their assigned button gets pressed.
"""
@app.callback(
    Output(component_id='vertex-graph', component_property='value'),
    [Input(component_id='btn-vertex-graph', component_property='n_clicks')]
)
def reset_vertex_input(n_clicks):
    return ""

@app.callback(
    Output(component_id='source-graph', component_property='value'),
    [Input(component_id='btn-edge-graph', component_property='n_clicks')]
)
def reset_source_input(n_clicks):
    return ""

@app.callback(
    Output(component_id='terminus-graph', component_property='value'),
    [Input(component_id='btn-edge-graph', component_property='n_clicks')]
)
def reset_terminus_input(n_clicks):
    return ""

@app.callback(
    Output(component_id='weight-graph', component_property='value'),
    [Input(component_id='btn-edge-graph', component_property='n_clicks')]
)
def reset_weight_input(n_clicks):
    return 1

@app.callback(
    Output(component_id='rm-vertex-graph', component_property='value'),
    [Input(component_id='btn-rm-vertex-graph', component_property='n_clicks')]
)
def reset_rm_vertex_input(n_clicks):
    return ""

@app.callback(
    Output(component_id='rm-source-graph', component_property='value'),
    [Input(component_id='btn-rm-edge-graph', component_property='n_clicks')]
)
def reset_rm_source_input(n_clicks):
    return ""

@app.callback(
    Output(component_id='rm-terminus-graph', component_property='value'),
    [Input(component_id='btn-rm-edge-graph', component_property='n_clicks')]
)
def reset_rm_terminus_input(n_clicks):
    return ""

#--- End of callbacks

if __name__ == '__main__':
    app.run_server(debug=True)
