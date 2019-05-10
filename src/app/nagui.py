# Plotly/Dash for the GUI and visualization.
import dash
import dash_core_components as dcc
import dash_html_components as html
import dash_bootstrap_components as dbc
from dash.dependencies import Input, Output, State

# igraph for the data structures and layout algorithms.
import networkx as nx

# draw and file for the wacky stuff with D.
import draw
import file
import subprocess as sbp

#--- Global variables

vis_height = '750px'
current_graph = nx.Graph()
blank_trace = {
    'data': [],
    'layout': {
        'title': 'Current graph',
        'xaxis': {
            'showline': False,
            'zeroline': False,
            'showticklabels': False
        },
        'yaxis': {
            'showline': False,
            'zeroline': False,
            'showticklabels': False
        },
        'hovermode': 'closest'
    }
}
current_trace = blank_trace
file_id = 0

#--- End of global variables

#--- GUI

external_stylesheets = [dbc.themes.BOOTSTRAP] #['https://codepen.io/chriddyp/pen/bWLwgP.css']
app = dash.Dash(__name__, external_stylesheets=external_stylesheets)

app.layout = html.Div(children=[
    html.H1('Graphs', className='m-4', id='header-graph'),

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
                    dbc.Button('Load graph', color='primary', id='btn-load-graph', className='mx-2'),
                    dbc.Button('Save graph', color='primary', id='btn-save-graph', className='mx-2')
                ], justify='center', className='m-4')
            ], width=3),
            dbc.Col([
                dbc.Row([
                    dbc.Col([
                        html.H4('The graph has 0 vertice(s) and 0 edge(s).', id='info-graph', className='mx-3'),
                    ], width=3),
                    dbc.Col([
                        html.H3('', id='additional-info-graph', className='mx-3')
                    ]),
                    dbc.Col([
                        dbc.Button('Previous step', color='info', id='btn-prev-graph', className='mx-2'),
                        dbc.Button('Next step', color='info', id='btn-next-graph', className='mx-2'),
                        dbc.Button('Reset', color='warning', id='btn-reset-graph', className='mx-2'),
                    ], width=3)
                ], justify='between'),
                dcc.Graph(
                    id='graph',
                    figure=current_trace,
                    style={'height': vis_height}
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
    Output(component_id='graph', component_property='figure'),
    [Input(component_id='btn-vertex-graph', component_property='n_clicks'),
     Input(component_id='btn-edge-graph', component_property='n_clicks'),
     Input(component_id='btn-rm-vertex-graph', component_property='n_clicks'),
     Input(component_id='btn-rm-edge-graph', component_property='n_clicks'),
     Input(component_id='btn-empty-graph', component_property='n_clicks')],
    [State(component_id='vertex-graph', component_property='value'),
     State(component_id='source-graph', component_property='value'),
     State(component_id='terminus-graph', component_property='value'),
     State(component_id='rm-vertex-graph', component_property='value'),
     State(component_id='rm-source-graph', component_property='value'),
     State(component_id='rm-terminus-graph', component_property='value'),
     State(component_id='weight-graph', component_property='value')]
)
def update_graph(n_clicks_vertex, n_clicks_edge, n_clicks_rm_v,
    n_clicks_rm_e, n_clicks_empty, vertex_value, source, terminus,
    rm_vertex, rm_source, rm_terminus, weight):
    global current_trace

    if n_clicks_vertex is not None and n_clicks_vertex > 0 and vertex_value != "":
        if not current_graph.has_node(vertex_value):
            current_graph.add_node(vertex_value)
            current_trace = draw.update_trace(current_trace, current_graph)
    elif n_clicks_edge is not None and n_clicks_edge > 0 and source != "" and terminus != "" and weight is not None:
        if current_graph.has_node(source) and current_graph.has_node(terminus):
            current_graph.add_edge(source, terminus, weight=weight)
            current_trace = draw.update_trace(current_trace, current_graph)
    elif n_clicks_rm_v is not None and n_clicks_rm_v > 0 and rm_vertex != "":
        if current_graph.has_node(rm_vertex):
            current_graph.remove_node(rm_vertex)
            if current_graph.number_of_nodes() > 0:
                current_trace = draw.update_trace(current_trace, current_graph)
            else:
                current_trace = blank_trace
    elif n_clicks_rm_e is not None and n_clicks_rm_e > 0 and rm_source != "" and rm_terminus != "":
        if current_graph.has_node(rm_source) and current_graph.has_node(rm_terminus) and current_graph.has_edge(rm_source, rm_terminus):
            current_graph.remove_edge(rm_source, rm_terminus)
            current_trace = draw.update_trace(current_trace, current_graph)
    elif n_clicks_empty is not None and n_clicks_empty:
        current_graph.clear()
        current_trace = blank_trace
    return current_trace

"""
Changing the information displayed at the top of the page every time the graph
is changed.
"""
@app.callback(
    Output(component_id='info-graph', component_property='children'),
    [Input(component_id='graph', component_property='figure')]
)
def update_graph_info(graph):
    return "The graph has {} vertice(s) and {} edge(s)".format(current_graph.number_of_nodes(), current_graph.number_of_edges())

"""
Input/Output of the current graph to/from text files.
"""
@app.callback(
    Output(component_id='header-graph', component_property='children'),
   # [Input(component_id='btn-load-graph', component_property='n_clicks'),
    [Input(component_id='btn-save-graph', component_property='n_clicks')]
)
def save_current_graph(n_clicks):
    global file_id
    if n_clicks is not None and n_clicks > 0:
        file.save_graph(current_graph, file_id)
        file_id += 1
        # sbp.run(["../algo/graph", "current-id", "pls work"])
        # print(nx.node_link_data(current_graph))
    return "Graphs"

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
    return 0

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
