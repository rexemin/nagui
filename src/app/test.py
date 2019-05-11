import dash
import dash_cytoscape as cyto
import dash_html_components as html

app = dash.Dash(__name__)

graph=[
    {'data': {'id': 'one', 'label': 'Node 1'}, 'position': {'x': 75, 'y': 75}},
    {'data': {'id': 'two', 'label': 'Node 2'}, 'position': {'x': 200, 'y': 200}},
    {'data': {'source': 'one', 'target': 'two'}}
]

app.layout = html.Div([
    cyto.Cytoscape(
        id='cytoscape-two-nodes',
        layout={'name': 'preset'},
        style={'width': '100%', 'height': '400px'},
        elements=graph
    )
])

if __name__ == '__main__':
    app.run_server(debug=True)
