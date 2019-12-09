#!/usr/bin/env bash
if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker is not installed.' >&2
  exit 1
fi
if ! [ -x ~/.local/bin/wechat.sh ]; then
  echo 'Install this script to ~/.local/bin/qq.sh' >&2
  cp $0 ~/.local/bin/wechat.sh
  WECHAT_P=/home/$(whoami)/.local/bin/wechat.sh
  wget https://raw.githubusercontent.com/ygcaicn/ubuntu_qq/master/wechat.png \
  -O ~/.local/share/icons/hicolor/256x256/apps/WINE_WECHAT.png
  cat <<-EOF > /home/$(whoami)/.local/share/applications/Wechat.desktop
[Desktop Entry]
Categories=Network;InstantMessaging;
Exec=${WECHAT_P}
Icon=/home/$(whoami)/.local/share/icons/hicolor/256x256/apps/WINE_WECHAT.png
Name=Wechat
NoDisplay=false
StartupNotify=true
Terminal=0
Type=Application
Name[en_US]=Wechat
Name[zh_CN]=微信
EOF
fi

container_id=$(docker ps -a | awk  'NR!=1 && $2 ~ /bestwu\/wechat/ {print $1}')
if [ -z "$container_id" ]; then
  docker container run -d --name wechat \
    --device /dev/snd \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
    -v $HOME:$HOME \
    -v $HOME/WeChatFiles:/WeChatFiles \
    -e DISPLAY=unix$DISPLAY \
    -e XMODIFIERS=@im=fcitx \
    -e QT_IM_MODULE=fcitx \
    -e GTK_IM_MODULE=fcitx \
    -e AUDIO_GID=`getent group audio | cut -d: -f3` \
    -e VIDEO_GID=`getent group video | cut -d: -f3` \
    -e GID=`id -g` \
    -e UID=`id -u` \
    bestwu/wechat
else
  container_stat=$(docker ps | awk  'NR!=1 && $2 ~ /bestwu\/wechat/ {print $1}')
  if [ -z "$container_stat" ]; then
    docker container start ${container_id}
  else
    docker container exec -d ${container_id} /entrypoint.sh
  fi
fi
