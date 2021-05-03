#!/bin/bash

# Git aliases

# Reset repo
alias git_oups="git clean -df && git reset --hard"

# Clean repo
alias git_clean="git reflog expire --expire=now --all && git gc --force --prune=now --aggressive"

# Add changes without whitespaces
alias git_no_ws="git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -"

# Stash changes
alias stash="git stash push -u -m "

# Pop stashed changes
alias pop="git stash pop --index"

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

# Clean local and remote branches
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

  printf "Delete remote branches ? "
  read NEXT_STEP

  if [ "$NEXT_STEP" = "y" ]; then
    local REMOTE_TO_DELETE=()
    # echo "Deleting remote branches"
    for branch in $(git branch -r | sed 's/^\s*//' | sed 's/^remotes\///' | grep -v 'master$'); do
      if [[ "$(git log --since "1 month ago" $branch | wc -l)" -eq 0 ]]; then
        local_branch_name=$(echo "$branch" | sed 's|origin/||')
        local TO_DELETE=0

        for branch_to_check in $(git branch -r | grep -E ".*(develop|master).*" | grep -v HEAD | sed "s|^\s*||g"); do
          local IS_MERGED=$(git branch -r --merged "$branch_to_check" | grep "$local_branch_name")
          local BRANCH_TIME_THRESHOLD="2 months ago"
          local NO_COMMIT_SINCE_LONG_TIME=$(git log --since "$BRANCH_TIME_THRESHOLD" "$branch" | wc -l)
          if [ $TO_DELETE -eq 0 ]; then
            local LAST_COMMIT_DATE=$(git log -1 --format="%cr" $branch)
            if [ -n "$IS_MERGED" ]; then
              echo "Deleting $local_branch_name, last commit was $LAST_COMMIT_DATE and branch has been merged in $branch_to_check"
              TO_DELETE=1
            elif [ $NO_COMMIT_SINCE_LONG_TIME -eq 0 ]; then
              echo "Deleting $local_branch_name, no changes since $BRANCH_TIME_THRESHOLD and last commit was $LAST_COMMIT_DATE"
              TO_DELETE=1
            fi
          fi
        done

        if [ $TO_DELETE -eq 1 ]; then
          REMOTE_TO_DELETE+=("$local_branch_name")
        fi
      fi
    done

    if [ ${#REMOTE_TO_DELETE[@]} -gt 0 ]; then
      git push --delete origin "${REMOTE_TO_DELETE[@]}"
    fi
  fi
}

# Clean local and remote branches, then clean repo
git_full_clean() {
  git_delete_branches_before
  git_clean
}

# Reset current branch to remote
git_reset_to_remote() {
  git reset --hard "origin/$(git_current_branch)"
}

# Test git conflict
conflict() {
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
