#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

GIT_PASSWORD="${INPUT_GIT_PASSWORD:-$GIT_PASSWORD}"
exec echo "$GIT_PASSWORD"
