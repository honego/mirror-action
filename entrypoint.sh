#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -eE

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
DEBUG="${INPUT_DEBUG:-${DEBUG:-"false"}}"
DRY_RUN="$INPUT_DRY_RUN"

if [ "$DEBUG" = "true" ]; then
    set -x
    echo >&2 "DEBUG: Environment Variables:"
    env
fi

if [ "$DRY_RUN" = "true" ]; then
    echo >&2 "DEBUG: DRY RUN MODE ENABLED"
    echo >&2 "DEBUG: Appending --dry-run to GIT_PUSH_ARGS."
    GIT_PUSH_ARGS="$GIT_PUSH_ARGS --dry-run"
fi

if [ "$HAS_CHECKED_OUT" != "true" ]; then
    echo >&2 "WARNING: repo not checked out; attempting checkout"
    echo >&2 "WARNING: this may result in missing commits in the remote mirror"
    echo >&2 "WARNING: this behavior is deprecated and will be removed in a future release"
    if [ -z "$SRC_REPO" ]; then
        SRC_REPO="https://github.com/$GITHUB_REPOSITORY.git"
        echo >&2 "WARNING: SRC_REPO env variable not defined. Assuming source repo is $SRC_REPO"
    fi
    git init 1> /dev/null
    git remote add origin "$SRC_REPO"
    git fetch --all > /dev/null 2>&1
fi

git config --global credential.username "$GIT_USERNAME"

if [ -n "$GIT_SSH_PRIVATE_KEY" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    echo "$GIT_SSH_PRIVATE_KEY" > "$HOME/.ssh/id_rsa"
    chmod 600 "$HOME/.ssh/id_rsa"

    if [ -n "$GIT_SSH_PUBLIC_KEY" ]; then
        echo "$GIT_SSH_PUBLIC_KEY" > "$HOME/.ssh/id_rsa.pub"
        chmod 600 "$HOME/.ssh/id_rsa.pub"
    fi

    if [ -n "$GIT_SSH_KNOWN_HOSTS" ]; then
        # Known hosts are provided.
        echo "$GIT_SSH_KNOWN_HOSTS" > "$HOME/.ssh/known_hosts"
        git config --global core.sshCommand "ssh -i $HOME/.ssh/id_rsa -o IdentitiesOnly=yes -o UserKnownHostsFile=$HOME/.ssh/known_hosts"
    elif [ "$GIT_SSH_NO_VERIFY_HOST" = "true" ]; then
        # No host was provided, but validation is allowed to be ignored.
        git config --global core.sshCommand "ssh -i $HOME/.ssh/id_rsa -o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
    else
        # Neither a host is provided nor is it allowed to be omitted.
        echo >&2 "WARNING: no known_hosts set and host verification is enabled (the default)"
        echo >&2 "WARNING: this job will fail due to host verification issues"
        echo >&2 "Please either provide the GIT_SSH_KNOWN_HOSTS or GIT_SSH_NO_VERIFY_HOST inputs"
        exit 1
    fi
else
    # HTTPS mode
    git config --global core.askPass /cred-helper.sh
    git config --global credential.helper cache
fi

git remote add "$REMOTE_NAME" "$REMOTE"

if [ "$INPUT_PUSH_ALL_REFS" != "false" ]; then
    # Push all Refs
    eval git push "$GIT_PUSH_ARGS" "$REMOTE_NAME" "\"refs/remotes/origin/*:refs/heads/*\""
else
    # Push a single Ref
    if [ "$HAS_CHECKED_OUT" != "true" ]; then
        echo >&2 "FATAL: You must upgrade to using actions inputs instead of args: to push a single branch"
        exit 1
    else
        eval git push -u "$GIT_PUSH_ARGS" "$REMOTE_NAME" "$GIT_REF"
    fi
fi
