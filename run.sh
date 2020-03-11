#!/bin/bash

python_env=app/env
graph_lib=app/lib/bin/graph.out
digraph_lib=app/lib/bin/digraph.out
network_lib=app/lib/bin/network.out

# Checking that the virtual environment exists.
if [ ! -d "$python_env/bin" ]
then
    echo "The virtual environment does not exist, creating it."
    python3 -m venv $python_env
    source $python_env/bin/activate
    echo "Installing dependencies."
    pip install -r requirements.txt
    deactivate
fi

# Checking the existence of the compiled library.
if [ ! -f $graph_lib ] || [ ! -f $digraph_lib ] || [ ! -f $network_lib ]
then
    echo "You do not have the compiled D library, please get it before running the interactive application."
else
    echo "Starting the application."
    source $python_env/bin/activate
    cd app/
    python index.py
fi
