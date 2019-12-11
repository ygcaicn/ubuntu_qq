#!/usr/bin/env bash

install(){
  if ! [ -x "$(command -v docker)" ]; then
    echo 'Error: docker is not installed.' >&2
    exit 1
  fi
  [ -n ~/.local/bin/ ] && mkdir -p ~/.local/bin/
  p=$(grep ~/.local/bin: ~/.bashrc)
  [ -n $p ] && echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> ~/.bashrc && source ~/.bashrc
  [ -n ~/.local/share/icons/hicolor/256x256/apps ] && mkdir -p ~/.local/share/icons/hicolor/256x256/apps

  if ! [ -x ~/.local/bin/wechat.sh ]; then
    echo 'Install this script to ~/.local/bin/wechat.sh' >&2
    #cp $0 ~/.local/bin/wechat.sh
    wget https://raw.githubusercontent.com/ygcaicn/ubuntu_qq/master/wechat.sh \
  -O ~/.local/bin/wechat.sh
    sed -i -r -e 's/^\s*remove.*install$/start/g' ~/.local/bin/wechat.sh
    chmod +x ~/.local/bin/wechat.sh
    ln -i ~/.local/bin/wechat.sh ~/.local/bin/wechat
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
  start
  else
    echo "already installed at ~/.local/bin/wechat.sh"
  fi
  return 0
}

remove(){
  [ -e ~/.local/bin/wechat.sh ] && rm -f ~/.local/bin/wechat.sh\
  && echo "remove ~/.local/bin/wechat.sh"

  [ -e ~/.local/bin/wechat ] && rm -f ~/.local/bin/wechat
  
  [ -e ~/.local/share/icons/hicolor/256x256/apps/WINE_WECHAT.png ] \
  && rm -f ~/.local/share/icons/hicolor/256x256/apps/WINE_WECHAT.png\
  && echo "remove ~/.local/share/icons/hicolor/256x256/apps/WINE_WECHAT.png"

  
  [ -e /home/$(whoami)/.local/share/applications/Wechat.desktop ] \
  && rm -f /home/$(whoami)/.local/share/applications/Wechat.desktop\
  && echo "remove ~/.local/share/applications/Wechat.desktop"

  return 0
}

removei(){
  imgs=$(docker images | awk '$1 ~ /bestwu\/wechat/ {print $3}')
  [[ -n $imgs ]] && docker rmi $imgs
  return 0
}

clean(){
  container_ids=$(docker ps -a | awk  'NR!=1 && $2 ~ /bestwu\/wechat/ {print $1}')
  if [[ -n "$container_ids" ]]; then
    docker container rm -f $container_ids
  fi
  return 0
}

update(){
  clean
  remove && install
  return 0
}

startContainer(){
  arg='--name script_wechat'
  if [[ "$1" == "instance" ]]; then
    arg='--rm'
  fi
  docker container run -d ${arg} \
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
  return 0
}

start(){
  container_id=$(docker ps -a | grep script_wechat | awk  '$2 ~ /bestwu\/wechat/ {print $1}')
  if [[ -z "$container_id" ]]; then
    startContainer
  else
    container_stat=$(docker ps | grep script_wechat | awk  '$2 ~ /bestwu\/wechat/ {print $1}')
    if [ -z "$container_stat" ]; then
      docker container start ${container_id}
    else
      docker container exec -d ${container_id} /entrypoint.sh
    fi
  fi
  return 0
}

starti(){
  startContainer instance
  return 0
}

help(){
  echo "wechat [-h] [-i] [-f] [-c] [--start|start] [--remove] [--instance]"
  echo "  -h, --help            Show help"
  echo "  -i, --install         Install this script to system"
  echo "  -f, --force           Force install or reinstall"
  echo "  -c, --clean           Clean all wechat container"
  echo "      --start           Start wechat"
  echo "      --update          Update script"
  echo "      --remove          Remove this script"
  echo "      --instance        Create a instance wechat container, you can create more then one using this option"
  return 0
}


REMOVE=''
INSTALL=''
REINSTALL=''
HELP=""
INSTANCE=""
CLEAN=""
UPDATE=""
START=""
while [[ $# > 0 ]];do
  key="$1"
  case $key in
      -i|--install)
      INSTALL="1"
      ;;
      --start|start)
      START="1"
      ;;
      --remove)
      REMOVE="1"
      ;;
      -f|--force)
      REINSTALL="1"
      ;;
      --instance)
      INSTANCE="1"
      ;;
      --update)
      UPDATE="1"
      ;;
      -c|--clean)
      CLEAN="1"
      ;;
      -h|--help)
      HELP="1"
      ;;
      *)
      echo "Unknown opt."
      help
      return
      ;;
  esac
  shift
done

main(){
  [[ "$REMOVE" == "1" ]] && remove && removei && return
  [[ "$INSTALL" == "1" ]] && install && return
  [[ "$REINSTALL" == "1" ]] && remove && install && return
  [[ "$INSTANCE" == "1" ]] && starti && return
  [[ "$CLEAN" == "1" ]] && clean && return
  [[ "$UPDATE" == "1" ]] && update && return
  [[ "$HELP" == "1" ]] && help && return
  [[ "$START" == "1" ]] && start && return
  remove && install
}
main