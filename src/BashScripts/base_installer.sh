#!/bin/bash


OSBOX_BIN_USR="osbox"

# installation log
log(){
    echo "$(date) : $1">>/var/log/osbox-install.log
    echo "$(date) : $1"
}


# is_command function
is_command() {
    # Checks for existence of string passed in as only function argument.
    # Exit value of 0 when exists, 1 if not exists. Value is the result
    # of the `command` shell built-in call.
    local check_command="$1"
    command -v "${check_command}" >/dev/null 2>&1
}


createUser(){
    # adduser
    log "Checking for $OSBOX_BIN_USR user."
    if id -u osbox >/dev/null 2>&1; then
        log "Skipping, user '${OSBOX_BIN_USR}' already exists."
    else
        useradd -m osbox
        log "Adding ${OSBOX_BIN_USR} user."
    fi

    # add to sudoers
    if [ -f /etc/sudoers.d/${OSBOX_BIN_USR} ]; then
       rm -f /etc/sudoers.d/${OSBOX_BIN_USR}
    fi
    echo "${OSBOX_BIN_USR} ALL=NOPASSWD: ${OSBOX_BIN_INSTALLDIR}osbox">/etc/sudoers.d/${OSBOX_BIN_USR}
}








# Installer!
bash /usr/local/osbox/osbox update


# check if avahi-daemon command exists.
if ! is_command avahi-daemon ; then
    echo "Error. avahi-daemon is not available."
    echo "Trying to install avahi-daemon."
    log "Trying to install avahi-daemon."
    /boot/dietpi/dietpi-software install 152 --unattended
    apt-get install -y avahi-utils libsodium23 libgd3 libzip4 libedit2 libxslt1.1
    #exit
else
    log "avahi-daemon is available"
fi


if ! is_command avahi-browse ; then
   log "Trying to install avahi-utils."
   apt-get install -y avahi-utils libsodium23 libgd3 libzip4 libedit2 libxslt1.1
else
   log "avahi-utils are available."
fi


if ! is_command nmap ; then
   log "Trying to install avahi-utils."
   apt-get install -y nmap
else
   log "avahi-utils are available."
fi

if ! is_command sqlite3 ; then
   log "Trying to install sqlite ."
   #//apt-get install -y nmap
   /boot/dietpi/dietpi-software install 87 --unattended

else
   log "sqlite is available."
fi


#ln -s /var/lib/dietpi/postboot.d/osbox-boot /usr/local/osbox/osbox-boot


if [  -f /var/lib/dietpi/postboot.d/requirements.sh  ]; then
    rm -f /var/lib/dietpi/postboot.d/requirements.sh
fi
#
if [ ! -f /var/lib/dietpi/postboot.d/requirements.sh  ]; then
  log "set boot-time requirements"

  echo '#!/bin/bash'>/var/lib/dietpi/postboot.d/requirements.sh
  chmod +x /var/lib/dietpi/postboot.d/requirements.sh

  echo "is_command() {">>/var/lib/dietpi/postboot.d/requirements.sh
  echo "  local check_command=\"\$1\" ">>/var/lib/dietpi/postboot.d/requirements.sh
  echo "  command -v \"\${check_command}\"  >/dev/null 2>&1">>/var/lib/dietpi/postboot.d/requirements.sh
  echo "}">>/var/lib/dietpi/postboot.d/requirements.sh




  echo "if ! is_command sqlite3 ; then">>/var/lib/dietpi/postboot.d/requirements.sh
  echo "   /boot/dietpi/dietpi-software install 87 --unattended">>/var/lib/dietpi/postboot.d/requirements.sh
  echo "fi">>/var/lib/dietpi/postboot.d/requirements.sh


  echo "if ! is_command git ; then">>/var/lib/dietpi/postboot.d/requirements.sh
  echo "   /boot/dietpi/dietpi-software install 17 --unattended">>/var/lib/dietpi/postboot.d/requirements.sh
  echo "fi">>/var/lib/dietpi/postboot.d/requirements.sh

  echo "#!/bin/bash">/var/lib/dietpi/postboot.d/requirements.sh
  echo "if ! is_command avahi-daemon ; then">>/var/lib/dietpi/postboot.d/requirements.sh
  echo "   /boot/dietpi/dietpi-software install 152 --unattended">>/var/lib/dietpi/postboot.d/requirements.sh
  echo "   apt-get install -y avahi-utils libsodium23 libgd3 libzip4 libedit2 libxslt1.1">>/var/lib/dietpi/postboot.d/requirements.sh
  echo "fi">>/var/lib/dietpi/postboot.d/requirements.sh

  #echo "#!/bin/bash">/var/lib/dietpi/postboot.d/requirements.sh
  echo "if ! is_command docker ; then">>/var/lib/dietpi/postboot.d/requirements.sh
  echo "   /boot/dietpi/dietpi-software install 162 --unattended">>/var/lib/dietpi/postboot.d/requirements.sh
  #  echo "   ">>/var/lib/dietpi/postboot.d/requirements.sh
  echo "fi">>/var/lib/dietpi/postboot.d/requirements.sh


  echo "/usr/bin/nohup /bin/bash /usr/local/osbox/bin/listen.sh > /dev/null &">>/var/lib/dietpi/postboot.d/requirements.sh

  docker pull jerryhopper/swoole:4.5.4-php7.3


  echo "bash /usr/local/osbox/src/BashScripts/base_installer.sh"
fi


# check if sqlite3 db exists.
#
#  /host/etc/osbox/master.db
#  /host/etc/osbox/osbox.db
if [ ! -f /etc/osbox/osbox.db ];then
  touch /etc/osbox/osbox.db
  sqlite3 -batch /etc/osbox/osbox.db "create table installog (id INTEGER PRIMARY KEY,Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,f TEXT);"
  sqlite3 -batch /etc/osbox/osbox.db "INSERT INTO table ( installog ) VALUES( 'osbox.db created' );"

fi




# check if avahi-daemon command exists.
if ! is_command docker ; then
    log  "Error. docker is not available,rebooting"
    reboot
else
    log "docker is available"
fi


chmod +x /usr/local/osbox/project/sw-osbox-core/src/www/server.php

createUser


# osbox-pipe-service!
if [ -d /var/osbox ]; then
  rm -rf /var/osbox
fi

if [ ! -d /var/osbox ]; then
  mkdir -p /var/osbox
fi

if [ ! -f /var/osbox/mypipe ]; then
  mkfifo /var/osbox/mypipe
fi

if [ -f /usr/local/osbox/lib/systemd/osbox-pipe.service ]; then
  rm -f /usr/local/osbox/lib/systemd/osbox-pipe.service
fi
#cp /usr/local/osbox/lib/systemd/osbox-pipe.service /etc/systemd/system
#systemctl daemon-reload







# -env AUTORELOAD_PROGRAMS="swoole" -env AUTORELOAD_ANY_FILES=0

docker run -d --name osbox-core --env AUTORELOAD_PROGRAMS="swoole" --env AUTORELOAD_ANY_FILES=0 --restart unless-stopped -v /usr/local/osbox/project/sw-osbox-core/src/www:/var/www  -v /var/osbox/mypipe:/hostpipe -v /var/osbox/response:/hostresponse -v /etc:/host/etc -p 81:9501 jerryhopper/swoole:4.5.4-php7.3



