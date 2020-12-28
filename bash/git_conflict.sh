#!/bin/bash

# Check if conflicts exists between current branch and provided one
test_git_conflict() {
  getBranch() {
    local BRANCH="$1"
    git branch -r | grep "$BRANCH" | sed "s| ||g"
  }

  getLocalBranch() {
    local BRANCH="$1"
    git branch | grep "$BRANCH" | sed "s| ||g"
  }

  SOURCE='origin/'
  TEST='origin/'
  CURRENT=$(git rev-parse --abbrev-ref HEAD)

  if [ $# -eq "0" ]; then
    echo 'Needs 1 or 2 arguments, branch to test within or source branch and branch to test within'
    exit 1
  elif [ $# -eq "1" ]; then
    TEST=$(getBranch "$1")
  elif [ $# -eq "2" ]; then
    SOURCE=$(getLocalBranch "$1")
    TEST=$(getBranch "$2")
  fi

  STASH=$(git stash push -u)

  if [ "${SOURCE}" == 'origin/' ]; then
    echo "Testing ${TEST} to merge into ${CURRENT}"
    git switch -d &>/dev/null
  else
    echo "Testing ${TEST} to merge into ${SOURCE}"
    git switch -d ${SOURCE} &>/dev/null
  fi

  MERGE=$(git merge -Xignore-space-at-eol -Xignore-cr-at-eol --no-ff -m "DO NOT PUSH THIS MERGE" "${TEST}")

  if [ $? -eq "0" ]; then
    echo 'No conflict detected, switching back to your current branch'
  else
    echo "${MERGE}" | grep CONFLICT
    echo 'Press enter to continue...'
    read
    git merge --abort &>/dev/null
    echo 'Switching back to your current branch'
  fi

  git switch - &>/dev/null

  if [ "${STASH}" != 'No changes to save' ]; then
    git stash pop &>/dev/null
  fi
}
