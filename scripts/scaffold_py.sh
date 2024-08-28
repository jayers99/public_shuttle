#!/bin/bash

# Check if the project name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <project-name>"
  exit 1
fi

# Set the project name from the first CLI parameter
PROJECT_NAME=$1

# Check if the project directory already exists
if [ -d "$PROJECT_NAME" ]; then
  echo "Error: Directory '$PROJECT_NAME' already exists."
  exit 1
fi

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

# Create a .gitignore file for Python
cat <<EOL > .gitignore
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
env/
venv/
ENV/
env.bak/
venv.bak/

# Pipenv files
*.env
.venv/

# Install packages directory
lib/
lib64/
__pypackages__/

# Setuptools distribution folder
build/
dist/
eggs/
*.egg-info/
.installed.cfg
*.egg

# PyInstaller
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
coverage.xml
*.cover
.hypothesis/
.cache
.pytest_cache/
nosetests.xml
coverage/

# MyPy
.mypy_cache/
.dmypy.json
dmypy.json

# PEP 582; used by e.g. github.com/David-OConnor/pyflow
__pypackages__/

# PyCharm
.idea/

# Pyre type checker
.pyre/

# Jupyter Notebook
.ipynb_checkpoints

# VS Code
.vscode/

# macOS
.DS_Store

# Logs and databases
*.log
*.sqlite3

# Local environment variables
.env
*.env
EOL

# Initialize a new git repository
git init
git add .
git commit -m "Initial project setup with directory structure, pipenv, and .gitignore"

# Output a message to indicate setup completion
echo "Project $PROJECT_NAME has been scaffolded with pipenv and Python 3.9!"
echo ".gitignore file has been created!"
echo "Git repository initialized and initial commit made."
