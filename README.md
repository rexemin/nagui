# Network Algorithms with a GUI (nagui)

A [Dash](https://plot.ly/dash/) application in Python 3 with a [D](https://dlang.org/) backend to create graphs, digraphs, and networks, and run common optimization algorithms on them.
The split between the front-end in Python and the back-end in D is a long story, but it grew out of an experiment I did during an undergraduate course.

## Dependencies

All the data structures and algorithms are located in the directory `app/lib`.
To compile them you need [rdmd](https://dlang.org/rdmd.html). 

The Dash application needs the following dependencies:

- dash
- dash_bootstrap_components
- dash_cytoscape
- numpy
- networkx

## Running it

There are different ways to run this program, depending on whether you have (or want to have) D installed.

### Using D and Python

If you have both languages, clone this repository and run the `install.sh` script. 
This script will create a Python virtual environment with all dependencies needed, and compile the complete D library.

After that, you can run `run.sh` to display the application locally.

### Using only Python

If you don't have, or don't want to use, D, you can download a version of nagui with the D library precompiled here.
After that, enter the main directory of the application and run `run.sh`.
If you don't already have a Python virtual environment, it will automatically create it.

### Alternatives

Of course, you can still manage everything manually. 
The D library has a makefile to compile it.
The entry point for the Dash application is the file `index.py`.
