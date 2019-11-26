#!/usr/bin/env bash
if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker is not installed.' >&2
  exit 1
fi
if ! [ -x ~/.local/bin/qq.sh ]; then
  echo 'Install this script to ~/.local/bin/qq.sh' >&2
  cp $0 ~/.local/bin/qq.sh
  QQ_P=/home/$(whoami)/.local/bin/qq.sh
  wget https://raw.githubusercontent.com/ygcaicn/ubuntu_qq/master/tim.png \
  -O ~/.local/share/icons/hicolor/256x256/apps/WINE_TIM.png
  cat <<-EOF > /home/$(whoami)/.local/share/applications/TIM.desktop
[Desktop Entry]
Categories=Network;InstantMessaging;
Exec=${QQ_P}
Icon=/home/$(whoami)/.local/share/icons/hicolor/256x256/apps/WINE_TIM.png
Name=TIM
NoDisplay=false
StartupNotify=true
Terminal=0
Type=Application
Name[en_US]=TIM
EOF
fi

container_id=$(docker ps -al | awk  'NR!=1 && $2 ~ /bestwu\/qq/ {print $1}')
if [ -z "$container_id" ]; then
  docker container run -d --name qq \
    --device /dev/snd \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
    -v $HOME:/home \
    -v /opt/qq:/home/qq \
    -v /mnt/Data:/mnt/Data \
    -e DISPLAY=unix$DISPLAY \
    -e XMODIFIERS=@im=fcitx \
    -e QT_IM_MODULE=fcitx \
    -e GTK_IM_MODULE=fcitx \
    -e AUDIO_GID=`getent group audio | cut -d: -f3` \
    -e VIDEO_GID=`getent group video | cut -d: -f3` \
    -e GID=`id -g` \
    -e UID=`id -u` \
    bestwu/qq:office
else
  container_stat=$(docker ps | awk  'NR!=1 && $2 ~ /bestwu\/qq/ {print $1}')
  if [ -z "$container_stat" ]; then
    docker container start ${container_id}
  else
    docker container exec -d ${container_id} /entrypoint.sh
  fi
fi

