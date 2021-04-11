#!/bin/bash

# If a variable pretty_current_branch is exported, we use it
if [ ! -z "$pretty_current_branch" ]; then
  bash -c "$pretty_current_branch"
else
  git rev-parse --abbrev-ref HEAD
fi
