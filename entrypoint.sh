#!/usr/bin/env bash

# Load pulse audio
pulseaudio -D --exit-idle-time=-1
# Create a virtual speaker output
pactl load-module module-null-sink sink_name=SpeakerOutput sink_properties=device.description="Dummy_Output"
# Create a virtual microphone
pacmd load-module module-virtual-source source_name=VirtualMicrophone

# Stand up a local server that serves the media files within opt/media
cd opt/media
python -m SimpleHTTPServer &>/dev/null

# Start Selenium Chrome Node
/opt/bin/entry_point.sh