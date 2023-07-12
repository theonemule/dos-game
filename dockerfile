FROM ubuntu:22.04

ENV USER=root
ENV PASSWORD=password1
ENV LANG=en_US.UTF-8 
ENV LANGUAGE=en_US.UTF-8 
ENV LC_ALL=C.UTF-8 
ENV DISPLAY=:0.0
ENV DEBIAN_FRONTEND=noninteractive 
ENV DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt-get update && \
  echo "tzdata tzdata/Areas select America" > ~/tx.txt && \
  echo "tzdata tzdata/Zones/America select New York" >> ~/tx.txt && \
  debconf-set-selections ~/tx.txt && \
  apt-get install -y \
      bzip2 \
      gstreamer1.0-plugins-good \
      gstreamer1.0-pulseaudio \
      gstreamer1.0-tools \
      libglu1-mesa \
      libgtk2.0-0 \
      libncursesw5 \
      libopenal1 \
      libsdl-image1.2 \
      libsdl-ttf2.0-0 \
      libsdl1.2debian \
      libsndfile1 \
      novnc \
      pulseaudio \
      supervisor \
      ucspi-tcp \
      wget \
      tightvncserver \
      ratpoison \
      dosbox \
      nginx && \
      rm -rf /var/lib/apt/lists/*

COPY default.pa client.conf /etc/pulse/
COPY nginx.conf /etc/nginx/
COPY webaudio.js /usr/share/novnc/core/

RUN sed -i "/import RFB/a \
      import WebAudio from '/core/webaudio.js'" \
    /usr/share/novnc/app/ui.js \
 && sed -i "/UI.rfb.resizeSession/a \
	var loc = window.location, new_uri; \
	if (loc.protocol === 'https:') { \
	    new_uri = 'wss:'; \
	} else { \
	    new_uri = 'ws:'; \
	} \
	new_uri += '//' + loc.host; \
	new_uri += '/audio'; \
      var wa = new WebAudio(new_uri); \
      document.addEventListener('keydown', e => { wa.start(); });" \
    /usr/share/novnc/app/ui.js

RUN   mkdir ~/.vnc/ && \
  mkdir ~/.dosbox && \
  echo $PASSWORD | vncpasswd -f > ~/.vnc/passwd && \
  chmod 0600 ~/.vnc/passwd && \
  echo "set border 0" > ~/.ratpoisonrc  && \
  echo "exec dosbox -conf ~/.dosbox/dosbox.conf -fullscreen -c 'MOUNT C: /dos' -c 'C:' -c 'cd keen' -c 'keen1'">> ~/.ratpoisonrc && \
  export DOSCONF=$(dosbox -printconf) && \
  cp $DOSCONF ~/.dosbox/dosbox.conf && \
  sed -i 's/usescancodes=true/usescancodes=false/' ~/.dosbox/dosbox.conf && \
  openssl req -x509 -nodes -newkey rsa:2048 -keyout ~/novnc.pem -out ~/novnc.pem -days 3650 -subj "/C=US/ST=NY/L=NY/O=NY/OU=NY/CN=NY emailAddress=email@example.com"

COPY keen /dos/keen


COPY supervisord.conf /etc/supervisor/supervisord.conf
ENTRYPOINT [ "supervisord", "-c", "/etc/supervisor/supervisord.conf" ]
