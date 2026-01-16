#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -eE

if [ "$DEBUG" = "true" ]; then
    set -x
fi

# Trust the workspace
git config --global --add safe.directory "$GITHUB_WORKSPACE"

# Default variable values
GIT_USERNAME="${INPUT_GIT_USERNAME:-${GIT_USERNAME:-"git"}}"
REMOTE="${INPUT_REMOTE:-"$*"}"
REMOTE_NAME="${INPUT_REMOTE_NAME:-"mirror"}"
GIT_SSH_PRIVATE_KEY="$INPUT_GIT_SSH_PRIVATE_KEY"
GIT_SSH_PUBLIC_KEY="$INPUT_GIT_SSH_PUBLIC_KEY"
GIT_REF="$INPUT_GIT_REF"
GIT_PUSH_ARGS="${INPUT_GIT_PUSH_ARGS:-"--tags --force --prune"}"
GIT_SSH_NO_VERIFY_HOST="$INPUT_GIT_SSH_NO_VERIFY_HOST"
GIT_SSH_KNOWN_HOSTS="$INPUT_GIT_SSH_KNOWN_HOSTS"
HAS_CHECKED_OUT="$(git rev-parse --is-inside-work-tree 2> /dev/null || true)"

if [ "$HAS_CHECKED_OUT" != "true" ]; then
    tee >&2 <<- 'EOF'
    WARNING: repo not checked out; attempting checkout
    WARNING: this may result in missing commits in the remote mirror
    WARNING: this behavior is deprecated and will be removed in a future release
EOF
    if [ "$SRC_REPO" = "" ]; then
        SRC_REPO="https://github.com/$GITHUB_REPOSITORY.git"
        tee >&2 <<- EOF
        WARNING: SRC_REPO env variable not defined
        Assuming source repo is $SRC_REPO"
EOF
    fi
    git init 1> /dev/null
    git remote add origin "$SRC_REPO"
    git fetch --all > /dev/null 2>&1
fi

git config --global credential.username "$GIT_USERNAME"

if [ "$GIT_SSH_PRIVATE_KEY" != "" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    echo "$GIT_SSH_PRIVATE_KEY" > "$HOME/.ssh/id_rsa"
    if [ "$GIT_SSH_PUBLIC_KEY" != "" ]; then
        echo "$GIT_SSH_PUBLIC_KEY" > "$HOME/.ssh/id_rsa.pub"
        chmod 600 "$HOME/.ssh/id_rsa.pub"
    fi
    chmod 600 "$HOME/.ssh/id_rsa"
    if [ "$GIT_SSH_KNOWN_HOSTS" != "" ]; then
        echo "$GIT_SSH_KNOWN_HOSTS" > "$HOME/.ssh/known_hosts"
        git config --global core.sshCommand "ssh -i $HOME/.ssh/id_rsa -o IdentitiesOnly=yes -o UserKnownHostsFile=$HOME/.ssh/known_hosts"
    else
        if [ "$GIT_SSH_NO_VERIFY_HOST" != "true" ]; then
            tee >&2 <<- 'EOF'
            WARNING: no known_hosts set and host verification is enabled (the default)
            WARNING: this job will fail due to host verification issues
            Please either provide the GIT_SSH_KNOWN_HOSTS or GIT_SSH_NO_VERIFY_HOST inputs
EOF
            exit 1
        else
            git config --global core.sshCommand "ssh -i $HOME/.ssh/id_rsa -o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
        fi
    fi
else
    git config --global core.askPass /cred-helper.sh
    git config --global credential.helper cache
fi

git remote add "$REMOTE_NAME" "$REMOTE"
if [ "$INPUT_PUSH_ALL_REFS" != "false" ]; then
    eval git push "$GIT_PUSH_ARGS" "$REMOTE_NAME" "\"refs/remotes/origin/*:refs/heads/*\""
else
    if [ "$HAS_CHECKED_OUT" != "true" ]; then
        tee >&2 <<- 'EOF'
        echo "FATAL: You must upgrade to using actions inputs instead of args: to push a single branch"
EOF
        exit 1
    else
        eval git push -u "$GIT_PUSH_ARGS" "$REMOTE_NAME" "$GIT_REF"
    fi
fi
