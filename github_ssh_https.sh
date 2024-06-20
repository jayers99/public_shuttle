#!/bin/bash

# Find all .git directories
repos=$(find ~ -name ".git" -type d)

for repo in $repos; do
  # Go to the parent directory of .git
  repo_dir=$(dirname "$repo")
  cd "$repo_dir"

  # Get the current SSH URL
  ssh_url=$(git remote get-url origin)

  # Convert SSH URL to HTTPS URL
  https_url=$(echo "$ssh_url" | sed -E 's/git@github.com:/https:\/\/github.com\//')

  # Set the new HTTPS URL
  git remote set-url origin "$https_url"

  echo "Changed $repo_dir from $ssh_url to $https_url"
done
