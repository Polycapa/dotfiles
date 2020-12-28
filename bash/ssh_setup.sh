#!/bin/bash

env=~/.ssh/agent.env

agent_load_env() { test -f "$env" && . "$env" >|/dev/null; }

agent_start() {
  (
    umask 077
    ssh-agent >|"$env"
  )
  . "$env" >|/dev/null
}

load_ssh_keys() {
  ssh_keys=(id_rsa github)
  for ssh_key in "${ssh_keys[@]}"; do
    local SSH_KEY=~/.ssh/$ssh_key
    if [ -f "$SSH_KEY" ]; then
      ssh-add "$SSH_KEY"
    fi
  done
}

agent_load_env

# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2= agent not running
agent_run_state=$(
  ssh-add -l >|/dev/null 2>&1
  echo $?
)

if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
  agent_start
  load_ssh_keys
elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
  load_ssh_keys
fi

unset env
