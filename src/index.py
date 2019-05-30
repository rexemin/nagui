import dash_core_components as dcc
import dash_html_components as html
import dash_bootstrap_components as dbc
from dash.dependencies import Input, Output

from nagui import app
from apps import nagui_g, nagui_d, nagui_n


app.layout = html.Div([
    dcc.Location(id='url', refresh=True),
    html.Div(id='page-content')
])

main_menu = html.Div([
    dbc.Container([
        dbc.Row([
            html.H1('Network Algorithms with GUI'),
        ], justify='center', className='m-3'),
        dbc.Row([
            html.H2('Made by: Ivan Alejandro Moreno Soto'),
        ], justify='center', className='m-3'),
        dbc.Row([
            dcc.Link('Graphs', href='graphs', className='btn btn-primary btn-lg m-2'),
            dcc.Link('Digraphs', href='digraphs', className='btn btn-primary btn-lg m-2'),
            dcc.Link('Networks', href='networks', className='btn btn-primary btn-lg m-2')
        ], justify='center', className='m-3')
    ])
])

@app.callback(Output('page-content', 'children'),
              [Input('url', 'pathname')])
def display_page(pathname):
    if pathname == '/graphs':
        nagui_g.current_graph.clear()
        return nagui_g.layout
    elif pathname == '/digraphs':
        nagui_d.current_digraph.clear()
        return nagui_d.layout
    elif pathname == '/networks':
        nagui_n.current_network.clear()
        return nagui_n.layout
    elif pathname == '/':
        return main_menu
    else:
        return '404'

if __name__ == '__main__':
    app.run_server(debug=True)
