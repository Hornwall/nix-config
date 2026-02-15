#!/bin/bash

# Check if wf-recorder is running
if pgrep -x "wf-recorder" > /dev/null; then
    echo '{"alt": "recording", "tooltip": "Recording"}'
fi
