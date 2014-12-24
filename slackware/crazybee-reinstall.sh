#!/bin/sh
## run as root

# Ryan P.C. McQuen | Everett, WA | ryan.q@linux.com

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version, with the following exception:
# the text of the GPL license may be omitted.

# This program is distributed in the hope that it will be useful, but
# without any warranty; without even the implied warranty of
# merchantability or fitness for a particular purpose. Compiling,
# interpreting, executing or merely reading the text of the program
# may result in lapses of consciousness and/or very being, up to and
# including the end of all existence and the Universe as we know it.
# See the GNU General Public License for more details.

# You may have received a copy of the GNU General Public License along
# with this program (most likely, a file named COPYING).  If not, see
# <http://www.gnu.org/licenses/>.

# curl https://raw.githubusercontent.com/ryanpcmcquen/linuxTweaks/master/slackware/crazybee-reinstall.sh | sh


if [ ! $UID = 0 ]; then
  cat << EOF
This script must be run as root.
EOF
  exit 1
fi

if [ "$( uname -m )" = "x86_64" ] && [ -e /lib/libc.so.6 ]; then
  export COMPAT32=yes;
fi

install_latest_pkg() {
  PACKAGE=$1
  cd $PACKAGE/ || cd ../$PACKAGE/
  ./$PACKAGE.SlackBuild
  ls -t --color=never /tmp/$PACKAGE-*_bbsb.txz | head -1 | xargs -i upgradepkg --reinstall --install-new {}
}

install_latest_pkg_compat() {
  PACKAGE=$1
  cd $PACKAGE/ || cd ../$PACKAGE/
  if [ "$COMPAT32" = yes ]; then
    COMPAT32=yes ./$PACKAGE.SlackBuild
  else
    ./$PACKAGE.SlackBuild
  fi
  ls -t --color=never /tmp/$PACKAGE-*_bbsb.txz | head -1 | xargs -i upgradepkg --reinstall --install-new {}
}


cd

cd Bumblebee-SlackBuilds/

git pull

./download.sh

groupadd bumblebee
## add all non-root users (except ftp) to bumblebee group
cat /etc/passwd | grep "/home" | cut -d: -f1 | sed '/ftp/d' | xargs -i usermod -G bumblebee -a {}

install_latest_pkg libbsd

install_latest_pkg bumblebee

install_latest_pkg bbswitch

install_latest_pkg_compat primus

cd ../nouveau-blacklist/
upgradepkg --reinstall xf86-video-nouveau-blacklist-noarch-1.txz
if [ -z "$( cat /etc/slackpkg/blacklist | grep xf86-video-nouveau )" ]; then
  echo xf86-video-nouveau >> /etc/slackpkg/blacklist
fi
if [ -z "$( cat /etc/slackpkg/blacklist | grep _bbsb )" ]; then
  echo "[0-9]+_bbsb" >> /etc/slackpkg/blacklist
fi

install_latest_pkg_compat nvidia-kernel

install_latest_pkg_compat nvidia-bumblebee

chmod +x /etc/rc.d/rc.bumblebeed
/etc/rc.d/rc.bumblebeed start

if [ -z "$( cat /etc/rc.d/rc.local | grep bumblebeed )" ]; then
echo "if [ -x /etc/rc.d/rc.bumblebeed ]; then
  /etc/rc.d/rc.bumblebeed start
fi" >> /etc/rc.d/rc.local
fi

if [ -z "$( cat /etc/rc.d/rc.local_shutdown | grep bumblebeed )" ]; then
echo "if [ -x /etc/rc.d/rc.bumblebeed ]; then
  /etc/rc.d/rc.bumblebeed stop
fi" >> /etc/rc.d/rc.local_shutdown
fi

echo "Please reboot to enjoy your new driver."


