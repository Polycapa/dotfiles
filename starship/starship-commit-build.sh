#!/bin/bash

# If a variable pretty_current_branch is exported, we use it
if [ -n "$commit_build" ]; then
  bash -c "$commit_build"
else
  echo ""
fi
