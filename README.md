# git-mirror-action

[![Build Status](https://img.shields.io/github/actions/workflow/status/honego/git-mirror-action/build.yaml?branch=master&logo=github)](https://github.com/honego/git-mirror-action)
[![GitHub Release](https://img.shields.io/github/release/honego/git-mirror-action.svg?logo=github)](https://github.com/honego/git-mirror-action/releases/latest)
[![GitHub License](https://img.shields.io/github/license/honeok/git-mirror-action.svg?logo=github)](https://github.com/honeok/git-mirror-action)

A GitHub Action for mirroring your repository to a different remote repository.

## Example workflows

### Mirror a repository with username/password over HTTPS

For example, this project uses the following workflow to mirror from GitHub to GitLab

```yaml
name: "GitHub Actions Mirror"

on:
  push:
    branches: [master]
  workflow_dispatch:

jobs:
  mirror2gitlab:
    name: "Mirror to gitlab"
    runs-on: ubuntu-latest

    steps:
      - name: "Checkout repository"
        uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: "Mirror to gitlab"
        uses: honeok/git-mirror-action@v1
        with:
          REMOTE: "https://gitlab.com/${{ github.repository }}.git"
          GIT_USERNAME: ${{ github.repository_owner }}
          GIT_PASSWORD: ${{ secrets.GITLAB_PASSWORD }}
```

Be sure to set the `GIT_PASSWORD` secret in your repo secrets settings.

**NOTE:** by default, all branches are pushed. If you want to avoid
this behavior, set `PUSH_ALL_REFS: "false"`

You can further customize the push behavior with the `GIT_PUSH_ARGS` parameter.
By default, this is set to `--tags --force --prune`

If something goes wrong, you can debug by setting `DEBUG: "true"`

### Mirror a repository using SSH

Pretty much the same, but using `GIT_SSH_PRIVATE_KEY` and `GIT_SSH_KNOWN_HOSTS`

```yaml
name: "GitHub Actions Mirror"

on:
  push:
    branches: [master]
  workflow_dispatch:

jobs:
  mirror2gitlab:
    name: "Mirror to gitlab"
    runs-on: ubuntu-latest

    steps:
      - name: "Checkout repository"
        uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: "Mirror to gitlab"
        uses: honeok/git-mirror-action@v1
        with:
          REMOTE: "ssh://git@gitlab.com/${{ github.repository }}.git"
          GIT_SSH_PRIVATE_KEY: ${{ secrets.GIT_SSH_PRIVATE_KEY }}
          GIT_SSH_KNOWN_HOSTS: ${{ secrets.GIT_SSH_KNOWN_HOSTS }}
```

`GIT_SSH_KNOWN_HOSTS` is expected to be the contents of a `known_hosts` file.

Be sure you set the secrets in your repo secrets settings!

**NOTE:** if you prefer to skip hosts verification instead of providing a known_hosts file,
you can do so by using the `GIT_SSH_NO_VERIFY_HOST` input option. e.g.

```yaml
name: "GitHub Actions Mirror"

on:
  push:
    branches: [master]
  workflow_dispatch:

jobs:
  mirror2gitlab:
    name: "Mirror to gitlab"
    runs-on: ubuntu-latest

    steps:
      - name: "Checkout repository"
        uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: "Mirror to gitlab"
        uses: honeok/git-mirror-action@v1
        with:
          REMOTE: git@gitlab.com:${{ github.repository }}.git
          GIT_SSH_PRIVATE_KEY: ${{ secrets.GIT_SSH_PRIVATE_KEY }}
          GIT_SSH_NO_VERIFY_HOST: "true"
```

**WARNING**: this setting is a compromise in security. Using known hosts is recommended.
