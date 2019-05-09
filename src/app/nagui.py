# Plotly/Dash for the GUI and visualization.
import dash
import dash_core_components as dcc
import dash_html_components as html
import dash_bootstrap_components as dbc
from dash.dependencies import Input, Output, State

# igraph for the data structures and layout algorithms.
import igraph as ig

# draw and file for the wacky stuff with D.
import draw
import file
import subprocess as sbp

#--- Global variables

vis_height = '750px'
current_graph = ig.Graph()
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
                    html.H5('Add new vertex:'),
                    dbc.Input(id='vertex-graph', bs_size='sm', type='text', className='mx-5 my-1'),
                    dbc.Button('Add vertex', color='primary', id='btn-vertex-graph', className='my-2'),
                ], justify='around', className='p-4'),
                dbc.Row([
                    html.H5('Add new edge:'),
                    dbc.Input(id='source-graph', type='text', className='mx-5 my-1'),
                    html.H6('to'),
                    dbc.Input(id='terminus-graph', type='text', className='mx-5 my-1'),
                    html.H6('With weight: '),
                    dbc.Input(id='weight-graph', type='number', className='mx-5 my-1'),
                    dbc.Button('Add edge', color='primary', id='btn-edge-graph', className='my-2')
                ], justify='around', className='p-4'),
                dbc.Row([
                    dbc.Button('Empty graph', color='primary', id='btn-empty-graph')
                ], justify='center', className='m-4'),
                dbc.Row([
                    dbc.Button('Load graph', color='primary', id='btn-load-graph', className='mx-2'),
                    dbc.Button('Save graph', color='primary', id='btn-save-graph', className='mx-2')
                ], justify='center', className='m-4')
            ], width=3),
            dbc.Col([
                dbc.Row([
                    dbc.Col([
                        html.H4('The graph has 0 vertice(s) and 0 edge(s).', id='info-graph', className='mx-3'),
                    ], width=5),
                    dbc.Col([
                        dbc.Button('Previous step', color='info', id='btn-prev-graph', className='mx-2'),
                        dbc.Button('Next step', color='info', id='btn-next-graph', className='mx-2'),
                        dbc.Button('Reset', color='warning', id='btn-reset-graph', className='mx-2'),
                    ], width=4)
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
Updating the graph every time a vertex or an edge are added.
"""
@app.callback(
    Output(component_id='graph', component_property='figure'),
    [Input(component_id='btn-vertex-graph', component_property='n_clicks'),
     Input(component_id='btn-edge-graph', component_property='n_clicks'),
     Input(component_id='btn-empty-graph', component_property='n_clicks')],
    [State(component_id='vertex-graph', component_property='value'),
     State(component_id='source-graph', component_property='value'),
     State(component_id='terminus-graph', component_property='value'),
     State(component_id='weight-graph', component_property='value')]
)
def update_graph(n_clicks_vertex, n_clicks_edge, n_clicks_empty, vertex_value, source, terminus, weight):
    global current_trace

    if n_clicks_vertex is not None and n_clicks_vertex > 0 and vertex_value != "":
        if vertex_value not in [v['name'] for v in current_graph.vs]:
            current_graph.add_vertex(vertex_value)
            current_trace = draw.update_trace(current_trace, current_graph)
    elif n_clicks_edge is not None and n_clicks_edge > 0 and source != "" and terminus != "" and weight is not None:
        vertices = [v['name'] for v in current_graph.vs]
        if source in vertices and terminus in vertices:
            id_source = draw.find_vertex_id(current_graph, source)
            id_terminus = draw.find_vertex_id(current_graph, terminus)
            current_graph.add_edges([(id_source, id_terminus)])
            current_trace = draw.update_trace(current_trace, current_graph)
            print(current_graph)
    elif n_clicks_empty is not None and n_clicks_empty:
        ids = [v.index for v in current_graph.vs]
        current_graph.delete_vertices(ids)
        current_trace = blank_trace
    return current_trace

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

"""
Changing the information displayed at the top of the page every time the graph
is changed.
"""
@app.callback(
    Output(component_id='info-graph', component_property='children'),
    [Input(component_id='graph', component_property='figure')]
)
def update_graph_info(graph):
    return "The graph has {} vertice(s) and {} edge(s)".format(current_graph.vcount(), current_graph.ecount())

"""
Input/Output of the current graph to/from text files.
"""
@app.callback(
    Output(component_id='header-graph', component_property='children'),
   # [Input(component_id='btn-load-graph', component_property='n_clicks'),
    [Input(component_id='btn-save-graph', component_property='n_clicks')]
)
def save_current_graph(n_clicks):
    #file.save_graph(current_graph)
    sbp.run(["../algo/graph", "current-id", "pls work"])
    return "Graphs"

#--- End of callbacks

if __name__ == '__main__':
    app.run_server(debug=True)
