#!/usr/bin/env bash
set -euo pipefail

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required to generate GlobalTranslator.xcodeproj from project.yml" >&2
  exit 1
fi

xcodegen generate
