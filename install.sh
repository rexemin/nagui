#!/bin/bash

# Directories to install the app.
data_dir=app/data
env_name=app/env

echo "Creating the data directory."
mkdir $data_dir

# Making the Python environment.
echo "Creating the virtual Python environment."
python3 -m venv $env_name
source $env_name/bin/activate
pip install -r requirements.txt

# Compiling the D library.
echo "Compiling the D library."
cd app/lib
make
