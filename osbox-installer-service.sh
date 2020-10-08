#!/bin/bash

# installation log
is_running() {
    ps -o comm= -C "$1" 2>/dev/null | grep -x "$1" >/dev/null 2>&1
}


is_command() {
    local check_command="$1"
    command -v "${check_command}" >/dev/null 2>&1
}

log(){
    echo "$(date) : $1">>/var/log/osbox-installer-service.log
    echo "$(date) : $1"
}

start_osboxcore(){
  # check if container is available
  # -env AUTORELOAD_PROGRAMS="swoole" -env AUTORELOAD_ANY_FILES=0
  if [ "$(docker ps -a|grep osbox-core)" ]; then
      log "Disabling installer service"
      systemctl stop osbox-installer
      systemctl disable osbox-installer
  else
      log "Starting  docker container"
      docker run -d --name osbox-core --env AUTORELOAD_PROGRAMS="swoole" --env AUTORELOAD_ANY_FILES=0 --restart unless-stopped -v /usr/local/osbox/project/sw-osbox-core/src/www:/var/www  -v /var/osbox:/host/osbox -v /etc:/host/etc -p 81:9501 jerryhopper/swoole:4.5.4-php7.3
      if ! "$?" = "0"; then
        log "ERROR!  docker returned error. "
      else
        log "Disabling installer service"
        systemctl stop osbox-installer
        systemctl disable osbox-installer
      fi
      #systemctl enable osbox-installer



  fi

}

install_docker(){
  /boot/dietpi/dietpi-software install 162 --unattended
  if ! "$?" = "0"; then
    reboot
  fi
  log "Pulling image"
  docker pull jerryhopper/swoole:4.5.4-php7.3

}




log "osbox-installer-service"



# Loop until install-stage is finished.
while true; do

  # check if dietpi is installed completely
  if [ -f /boot/dietpi/.installed ] ; then

    # Check if docker is available.
    if ! is_command docker ; then
      log "Docker is not available"
      ## checking if "apt" is running
      if is_running apt; then
          log "apt is running"
          exit
      else
          log "Installing docker"
          install_docker


          exit
      fi

    else
      ## docker exists
      #log "Docker exists"

      start_osboxcore



      exit
    fi
  else
    log "sleep 60"
    sleep 60
  fi
done



