#!/bin/bash

# Function to list dependencies using otool
list_deps() {
    otool -L "$1" | awk '{print $1}' | grep -v ':$' | grep -v '^@'
}

# Function to recursively explore dependencies
explore_deps() {
    local binary="$1"
    local indent="$2"
    local deps=$(list_deps "$binary")

    for dep in $deps; do
        echo "${indent}${dep}"
        if [ ! "${dep}" == "${binary}" ] && [ ! "${visited[${dep}]}" ]; then
            visited["${dep}"]=1
            explore_deps "${dep}" "    ${indent}"
        fi
    done
}

declare -A visited

binary_path="$1"

if [ -z "${binary_path}" ]; then
    echo "Usage: $0 <binary_path>"
    exit 1
fi

explore_deps "${binary_path}" ""
