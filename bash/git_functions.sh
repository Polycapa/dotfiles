#!/bin/bash

# Git aliases

# Reset repo
alias git_oups="git clean -df && git reset --hard"

# Clean repo
alias git_clean="git reflog expire --expire=now --all && git gc --force --prune=now --aggressive"

# Add changes without whitespaces
alias git_no_ws="git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -"

# Test conflict alias
alias conflict="test_git_conflict"

# Stash changes
alias stash="git stash push -u -m "

# Switch to latest branch
alias g-="git switch -"

# Mark directory as unchanged
git_assume_unchanged() {
  find "$1" -type f -exec echo "{}" \; -exec git update-index --assume-unchanged "{}" \;
}

# Unmark directory as unchanged
git_no_assume_unchanged() {
  find "$1" -type f -exec echo "{}" \; -exec git update-index --no-assume-unchanged --verbose "{}" \;
}

# Return branch name
get_rebase_branch() {
  local BRANCH=$(git branch -r | grep "$1" | sed "s| ||g" | sed "s|origin\/||")
  echo -n "$BRANCH"
}

# Switch to a branch resetted to origin
git_get_rebased() {
  local BRANCH=$(get_rebase_branch "$1")
  git stash -u
  git fetch
  git switch "$BRANCH"
  git reset --hard "origin/$BRANCH"
  git stash pop
}

# Get current branch
git_current_branch() {
  local BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo -n "$BRANCH"
}

# Rebase on branch
git_rebase_on() {
  local BRANCH=$(get_rebase_branch "$1")
  git rebase --rebase-merges -Xignore-space-at-eol -Xignore-cr-at-eol "origin/$BRANCH"
}

# Rebase interactive on a branch
git_rebase_interactive_on() {
  local BRANCH=$(get_rebase_branch "$1")
  git rebase -i --rebase-merges -Xignore-space-at-eol -Xignore-cr-at-eol "origin/$BRANCH"
}

readInput() {
  local MESSAGE="$1"
  printf "$MESSAGE"
  read USER_INPUT
  if [ "$USER_INPUT" = "y" ] || [ "$USER_INPUT" = "Y" ]; then
    return 0
  else
    return 1
  fi
}

# Clean local branches
git_delete_branches_before() {
  echo "Deleting local branches"
  git fetch -p
  for branch in $(git branch | sed 's/^\s*//' | sed 's/^remotes\///' | grep -v 'master$'); do
    if [[ "$(git log --since "2 weeks ago" $branch | wc -l)" -eq 0 ]]; then
      local_branch_name=$(echo "$branch" | sed 's|origin/||')
      local HAS_REMOTE=$(git branch -r | grep "$local_branch_name")
      if [ -z "$HAS_REMOTE" ]; then
        git branch -d $local_branch_name
        if [ $? -ne 0 ]; then
          readInput "Check logs ? "
          if [ $? -eq 0 ]; then
            git log $local_branch_name
          fi
          readInput "Delete branch ? "
          if [ $? -eq 0 ]; then
            git branch -D $local_branch_name
          fi
        fi
      fi
    fi
  done
}

git_full_clean() {
  git_delete_branches_before
  git_clean
}
