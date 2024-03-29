#!/bin/bash

if which swiftformat >/dev/null; then
  cd ios && swiftformat --quiet .
else
  echo "error: SwiftFormat not installed, install with 'brew install swiftformat' (or manually from https://github.com/nicklockwood/SwiftFormat)"
  exit 1
fi
