#!/bin/bash

# Check if the project name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <project-name>"
  exit 1
fi

# Set the project name from the first CLI parameter
PROJECT_NAME=$1

# Create the project directory
mkdir $PROJECT_NAME
cd $PROJECT_NAME || exit

# Initialize pipenv with Python 3.9
pipenv --python 3.9

# Create the directory structure
mkdir ${PROJECT_NAME//-/_} tests scripts
touch ${PROJECT_NAME//-/_}/__init__.py ${PROJECT_NAME//-/_}/session.py
touch tests/__init__.py tests/test_session.py
touch scripts/run.py README.md setup.py

# Install required packages
pipenv install requests

# Output a message to indicate setup completion
echo "Project $PROJECT_NAME has been scaffolded with pipenv and Python 3.9!"
