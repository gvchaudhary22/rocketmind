#!/usr/bin/env bash
# RocketMind eval harness
# Writes the executable eval artifacts promised by /rocketmind:eval.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

node "$ROOT_DIR/bin/eval-contract.js" "$@"
