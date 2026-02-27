#!/bin/bash

if command -v voxtype >/dev/null 2>&1; then
  voxtype status --format json --icon-theme omarchy
elif [ -x /run/current-system/sw/bin/voxtype ]; then
  /run/current-system/sw/bin/voxtype status --format json --icon-theme omarchy
fi
