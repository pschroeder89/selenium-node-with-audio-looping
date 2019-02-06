FROM selenium/node-chrome-debug:3.141.59

USER root
# Install pulse audio and python
RUN apt-get -qq update && apt-get -qq install -y pulseaudio pavucontrol python

# Copy the media folder of this repo to opt/media in the container
RUN mkdir -p /opt/media
COPY media /opt/media/

# Use custom entrypoint
COPY entrypoint.sh /opt/bin/entrypoint.sh

USER seluser

ENTRYPOINT ["sh", "/opt/bin/entrypoint.sh"]