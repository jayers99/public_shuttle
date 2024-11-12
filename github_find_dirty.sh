for dir in */; do
  if [ -d "$dir/.git" ]; then
    cd "$dir"
    branch=$(git rev-parse --abbrev-ref HEAD)
    status=$(git status -uno | grep "Your branch is ahead")
    if [ -z "$status" ]; then
      echo "$dir is up to date on branch $branch."
    else
      echo "$dir has unpushed commits on branch $branch."
    fi
    cd ..
  fi
done
