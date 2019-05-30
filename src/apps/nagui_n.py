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
import apps.file as file
import subprocess as sbp

#--- Global variables

vis_height = '750px'
current_network = nx.DiGraph()
original_network = nx.DiGraph()
file_id = 0
info = ''

#--- End of global variables

def update_vertices_info(network, vertex = None):
    # If vertex is None, update every vertex.
    if vertex is None:
        nodes = current_network.nodes
    else:
        nodes = [vertex]

    for v in nodes:
        if current_network.in_degree(v) == 0:
            current_network.nodes[v]['type'] = 'source'
            if 'flow' in current_network.nodes[v]:
                current_network.nodes[v]['info'] = '+ {}, {}'.format(v, current_network.nodes[v]['flow'])
            elif 'min_flow' in current_network.nodes[v]:
                current_network.nodes[v]['info'] = '+ {}, {}/{}'.format(v, current_network.nodes[v]['min_flow'], current_network.nodes[v]['max_flow'])
            else:
                current_network.nodes[v]['info'] = '+ {}'.format(v)
        elif current_network.out_degree(v) == 0:
            current_network.nodes[v]['type'] = 'sink'
            if 'flow' in current_network.nodes[v]:
                current_network.nodes[v]['info'] = '- {}, {}'.format(v, current_network.nodes[v]['flow'])
            elif 'min_flow' in current_network.nodes[v]:
                current_network.nodes[v]['info'] = '- {}, {}/{}'.format(v, current_network.nodes[v]['min_flow'], current_network.nodes[v]['max_flow'])
            else:
                current_network.nodes[v]['info'] = '- {}'.format(v)
        else:
            current_network.nodes[v]['type'] = 'pass'
            if 'flow' in current_network.nodes[v]:
                current_network.nodes[v]['info'] = '{}, {}'.format(v, current_network.nodes[v]['flow'])
            elif 'min_flow' in current_network.nodes[v]:
                current_network.nodes[v]['info'] = '{}, {}/{}'.format(v, current_network.nodes[v]['min_flow'], current_network.nodes[v]['max_flow'])
            else:
                current_network.nodes[v]['info'] = '{}'.format(v)

#--- GUI

# external_stylesheets = [dbc.themes.BOOTSTRAP] #['https://codepen.io/chriddyp/pen/bWLwgP.css']
# app = dash.Dash(__name__, external_stylesheets=external_stylesheets)

# app.
layout = html.Div(children=[
    dbc.Container([
        dbc.Row([
            dbc.Col([
                html.H1('Networks', className='m-4', id='header-network'),
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
                        dbc.Input(id='vertex-network', type='text', className='mx-1 my-1'),
                    ], width=6),
                    dbc.Col([
                        dbc.Button('Add vertex', color='primary', id='btn-vertex-network', className='my-2'),
                    ], width=3),
                ], justify='around', align='center', className='p-1'),
                html.Br(),
                dbc.Row([
                    dbc.Col([
                        html.H5('Add new edge:'),
                    ], width=3),
                    dbc.Col([
                        dbc.Input(id='source-network', type='text', className='mx-1 my-1'),
                    ], width=4),
                    dbc.Col([
                        html.H6('to'),
                    ], width=1),
                    dbc.Col([
                        dbc.Input(id='terminus-network', type='text', className='mx-1 my-1'),
                    ], width=4),
                ], justify='around', align='center', className='p-1'),
                dbc.Row([
                    dbc.Col([
                        html.H6('Capacity: '),
                    ], width=3),
                    dbc.Col([
                        dbc.Input(id='weight-network', type='number', className='mx-1 my-1'),
                    ], width=3),
                    dbc.Col([
                        html.H6('Restriction: '),
                    ], width=3),
                    dbc.Col([
                        dbc.Input(id='restriction-network', type='number', className='mx-1 my-1'),
                    ], width=3),
                ], justify='around', align='center'),
                dbc.Row([
                    dbc.Col([
                        html.H6('Cost: '),
                    ], width=3),
                    dbc.Col([
                        dbc.Input(id='cost-network', type='number', className='mx-1 my-1'),
                    ], width=3),
                    dbc.Col([
                        dbc.Button('Add edge', color='primary', id='btn-edge-network', className='my-1')
                    ], width=6),
                ], justify='around', align='center'),
                html.Br(),
                dbc.Row([
                    dbc.Col([
                        html.H5('Remove vertex:'),
                    ], width=3),
                    dbc.Col([
                        dbc.Input(id='rm-vertex-network', type='text', className='mx-1 my-1'),
                    ], width=6),
                    dbc.Col([
                        dbc.Button('Remove vertex', color='primary', id='btn-rm-vertex-network', className='my-2'),
                    ], width=3),
                ], justify='around', align='center', className='p-1'),
                html.Br(),
                dbc.Row([
                    dbc.Col([
                        html.H5('Remove edge:'),
                    ], width=2),
                    dbc.Col([
                        dbc.Input(id='rm-source-network', type='text', className='mx-1 my-1'),
                    ], width=3),
                    dbc.Col([
                        html.H6('to'),
                    ], width=1),
                    dbc.Col([
                        dbc.Input(id='rm-terminus-network', type='text', className='mx-1 my-1'),
                    ], width=3),
                    dbc.Col([
                        dbc.Button('Remove edge', color='primary', id='btn-rm-edge-network', className='my-2'),
                    ], width=3),
                ], justify='around', align='center', className='p-1'),
                html.Br(),
                dbc.Row([
                    dbc.Button('Empty network', color='warning', id='btn-empty-network', className='mx-2'),
                    # dbc.Button('Load network', color='primary', id='btn-load-network', className='mx-2'),
                    # dbc.Button('Save network', color='primary', id='btn-save-network', className='mx-2')
                ], justify='center', className='m-4')
            ], width=3),
            dbc.Col([
                dbc.Row([
                    dbc.Col([
                        html.H4('The network has 0 node(s) and 0 edge(s).', id='info-network', className='mx-3'),
                    ], width=4),
                    dbc.Col([
                        html.H3('', id='additional-info-network', className='mx-3')
                    ], width=4),
                    dbc.Col([
                        dbc.Row([
                            dbc.Col([
                                html.H5('Target flow: ')
                            ], width=4),
                            dbc.Col([
                                dbc.Input(id='target-flow', type='number', className='mx-1 my-2')
                            ], width=6)
                        ], align='center'),
                        dbc.Row([
                            dbc.Col([
                                dcc.Dropdown(
                                    id='drop-algo-network',
                                    options=[
                                        {'label': 'Ford-Fulkerson', 'value': 'ford'},
                                        {'label': 'Minimum cost with cycles', 'value': 'mincycle'},
                                        {'label': 'Minimum cost with paths', 'value': 'minpaths'},
                                        {'label': 'Simplex in networks', 'value': 'simplex'},
                                    ],
                                    clearable=False,
                                    value='ford'
                                )
                            ], width=6),
                            dbc.Col([
                                # dbc.Button('Previous step', color='info', id='btn-prev-network', className='mx-2'),
                                # dbc.Button('Next step', color='info', id='btn-next-network', className='mx-2'),
                                dbc.Button('Run', color='info', id='btn-run-network', className='mx-2'),
                                dbc.Button('Reset', color='warning', id='btn-reset-network', className='mx-2'),
                            ], width=6)
                        ], align='center')
                    ], width=4),
                ], justify='between'),
                cyto.Cytoscape(
                    id='network',
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
                                'label': 'data(info)'
                            }
                        },
                        {
                            'selector': 'edge',
                            'style': {
                                'label': 'data(info)',
                                'curve-style': 'bezier',
                                'target-arrow-shape': 'vee'
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
Updating the network every time a vertex or an edge are added/removed.
"""
@app.callback(
    Output(component_id='network', component_property='elements'),
    [Input(component_id='btn-vertex-network', component_property='n_clicks_timestamp'),
     Input(component_id='btn-edge-network', component_property='n_clicks_timestamp'),
     Input(component_id='btn-rm-vertex-network', component_property='n_clicks_timestamp'),
     Input(component_id='btn-rm-edge-network', component_property='n_clicks_timestamp'),
     Input(component_id='btn-run-network', component_property='n_clicks_timestamp'),
     Input(component_id='btn-reset-network', component_property='n_clicks_timestamp'),
     Input(component_id='btn-empty-network', component_property='n_clicks_timestamp')],
    [State(component_id='vertex-network', component_property='value'),
     State(component_id='source-network', component_property='value'),
     State(component_id='terminus-network', component_property='value'),
     State(component_id='restriction-network', component_property='value'),
     State(component_id='cost-network', component_property='value'),
     State(component_id='rm-vertex-network', component_property='value'),
     State(component_id='rm-source-network', component_property='value'),
     State(component_id='rm-terminus-network', component_property='value'),
     State(component_id='weight-network', component_property='value'),
     State(component_id='target-flow', component_property='value'),
     State('drop-algo-network', 'value'),
     State('network', 'elements')]
)
def update_network(btn_vertex, btn_edge, btn_rm_v, btn_rm_e, btn_run, btn_reset, btn_empty, vertex_value, source, terminus,
    restriction, cost, rm_vertex, rm_source, rm_terminus, weight, target_flow, algorithm, elements):
    global current_network
    global file_id
    global original_network
    global info

    info = ''
    buttons = np.array([btn if btn is not None else 0 for btn in (btn_vertex, btn_edge, btn_rm_v, btn_rm_e, btn_run, btn_reset, btn_empty)])
    btn_pressed = np.argmax(buttons)

    if btn_vertex is not None and btn_pressed == 0 and vertex_value != "":
        input = vertex_value.split('/')
        if not current_network.has_node(input[0]):
            if len(input) == 1:
                current_network.add_node(input[0], type='source', info='+ {}'.format(input[0]))
            elif len(input) == 2:
                flow = int(input[1])
                current_network.add_node(input[0], type='source', flow=flow, info='+ {}, {}'.format(input[0], flow))
            elif len(input) >= 3:
                min_f = int(input[1])
                max_f = int(input[2])
                if min_f >= 0 and min_f <= max_f:
                    current_network.add_node(input[0], type='source', min_flow=min_f, max_flow=max_f, info='+ {}, {}/{}'.format(input[0], min_f, max_f))
                else:
                    info = 'Invalid restrictions for vertex {}.'.format(input[0])
            elements = nx.readwrite.json_graph.cytoscape_data(current_network)
            elements = elements['elements']['nodes'] + elements['elements']['edges']
        else:
            info = 'Vertex {} is already on the network.'.format(input[0])
    elif btn_edge is not None and btn_pressed == 1 and source != "" and terminus != "" and weight is not None and restriction is not None and cost is not None:
        if current_network.has_node(source) and current_network.has_node(terminus) and weight >= restriction and restriction >= 0 and weight >= 0:
            current_network.add_edge(source, terminus, weight=weight, restriction=restriction, flow=0, cost=cost, info='r:{}, f:{}, q:{}, c:{}'.format(restriction, 0, weight, cost))
            update_vertices_info(current_network, source)
            update_vertices_info(current_network, terminus)
            elements = nx.readwrite.json_graph.cytoscape_data(current_network)
            elements = elements['elements']['nodes'] + elements['elements']['edges']
        elif not current_network.has_node(source) and current_network.has_node(terminus):
            info = 'Vertex {} is not on the network.'.format(source)
        elif current_network.has_node(source) and not current_network.has_node(terminus):
            info = 'Vertex {} is not on the network.'.format(terminus)
        elif not current_network.has_node(source) and not current_network.has_node(terminus):
            info = 'Vertices {} and {} are not on the network.'.format(source, terminus)
        elif weight < restriction:
            info = "The capacity of the edge can't be less than the restriction."
        elif restriction < 0:
            info = "The minimum restriction can't be negative."
        else:
            info = "The capacity of the edge can't be negative."
    elif btn_rm_v is not None and btn_pressed == 2 and rm_vertex != "":
        if current_network.has_node(rm_vertex):
            current_network.remove_node(rm_vertex)
            update_vertices_info(current_network)
            elements = nx.readwrite.json_graph.cytoscape_data(current_network)
            elements = elements['elements']['nodes'] + elements['elements']['edges']
        else:
            info = 'Vertex {} is not on the network.'.format(rm_vertex)
    elif btn_rm_e is not None and btn_pressed == 3 and rm_source != "" and rm_terminus != "":
        if current_network.has_node(rm_source) and current_network.has_node(rm_terminus) and current_network.has_edge(rm_source, rm_terminus):
            current_network.remove_edge(rm_source, rm_terminus)
            update_vertices_info(current_network, rm_source)
            update_vertices_info(current_network, rm_terminus)
            elements = nx.readwrite.json_graph.cytoscape_data(current_network)
            elements = elements['elements']['nodes'] + elements['elements']['edges']
        elif not current_network.has_node(rm_source) and current_network.has_node(rm_terminus):
            info = 'Vertex {} is not on the network.'.format(rm_source)
        elif current_network.has_node(rm_source) and not current_network.has_node(rm_terminus):
            info = 'Vertex {} is not on the network.'.format(rm_terminus)
        elif not current_network.has_node(rm_source) and not current_network.has_node(rm_terminus):
            info = 'Vertices {} and {} are not on the network.'.format(rm_source, rm_terminus)
        else:
            info = "There isn't an edge between vertices {} and {}.".format(rm_source, rm_terminus)
    elif btn_run is not None and btn_pressed == 4:
        if ((algorithm == 'mincycle' or algorithm == 'minpaths') and target_flow != '' and target_flow != ' ' and target_flow is not None) or algorithm == 'ford' or algorithm == 'simplex':
            file_path = file.save_graph(current_network, file_id)
            original_network = current_network
            if algorithm == 'ford' or algorithm == 'simplex':
                sbp.run(["./algo/network.out", file_path, str(file_id), algorithm, '0'])
            else:
                sbp.run(["./algo/network.out", file_path, str(file_id), algorithm, str(target_flow)])

            result, is_a_graph, info = file.load_network(file_id)
            if is_a_graph:
                current_network = result
                update_vertices_info(current_network)
                file_id += 1
            else:
                info = result
            elements = nx.readwrite.json_graph.cytoscape_data(current_network)
            elements = elements['elements']['nodes'] + elements['elements']['edges']
    elif btn_reset is not None and btn_pressed == 5:
        current_network = original_network
        elements = nx.readwrite.json_graph.cytoscape_data(current_network)
        elements = elements['elements']['nodes'] + elements['elements']['edges']
        if file_id > 1:
            file_id -= 1
    elif btn_empty is not None and btn_pressed == 6:
        current_network.clear()
        elements = nx.readwrite.json_graph.cytoscape_data(current_network)
        elements = elements['elements']['nodes'] + elements['elements']['edges']
    return elements

"""
Displaying additional information,
"""
@app.callback(
    Output('additional-info-network', 'children'),
    [Input('network', 'elements')]
)
def update_additional_info(network):
    global info
    return info

"""
Changing the information displayed at the top of the page every time the network
is changed.
"""
@app.callback(
    Output(component_id='info-network', component_property='children'),
    [Input(component_id='network', component_property='elements')]
)
def update_network_info(network):
    return "The network has {} node(s) and {} edge(s)".format(current_network.number_of_nodes(), current_network.number_of_edges())

"""
Resetting the Inputs every time their assigned button gets pressed.
"""
@app.callback(
    Output(component_id='vertex-network', component_property='value'),
    [Input(component_id='btn-vertex-network', component_property='n_clicks')]
)
def reset_vertex_input(n_clicks):
    return ""

@app.callback(
    Output(component_id='source-network', component_property='value'),
    [Input(component_id='btn-edge-network', component_property='n_clicks')]
)
def reset_source_input(n_clicks):
    return ""

@app.callback(
    Output(component_id='terminus-network', component_property='value'),
    [Input(component_id='btn-edge-network', component_property='n_clicks')]
)
def reset_terminus_input(n_clicks):
    return ""

@app.callback(
    Output(component_id='weight-network', component_property='value'),
    [Input(component_id='btn-edge-network', component_property='n_clicks')]
)
def reset_weight_input(n_clicks):
    return 1

@app.callback(
    Output(component_id='restriction-network', component_property='value'),
    [Input(component_id='btn-edge-network', component_property='n_clicks')]
)
def reset_weight_input(n_clicks):
    return 0

@app.callback(
    Output(component_id='cost-network', component_property='value'),
    [Input(component_id='btn-edge-network', component_property='n_clicks')]
)
def reset_weight_input(n_clicks):
    return 0

@app.callback(
    Output(component_id='rm-vertex-network', component_property='value'),
    [Input(component_id='btn-rm-vertex-network', component_property='n_clicks')]
)
def reset_rm_vertex_input(n_clicks):
    return ""

@app.callback(
    Output(component_id='rm-source-network', component_property='value'),
    [Input(component_id='btn-rm-edge-network', component_property='n_clicks')]
)
def reset_rm_source_input(n_clicks):
    return ""

@app.callback(
    Output(component_id='rm-terminus-network', component_property='value'),
    [Input(component_id='btn-rm-edge-network', component_property='n_clicks')]
)
def reset_rm_terminus_input(n_clicks):
    return ""

#--- End of callbacks

if __name__ == '__main__':
    app.run_server(debug=True)
