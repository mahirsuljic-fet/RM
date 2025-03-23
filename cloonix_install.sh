#!/bin/bash

#############
# VARIABLES #
#############

# version
v_major="45"
v_minor="01"

# colors
green='\033[3;32m'
yellow='\033[0;33m'
white='\033[0m'

# names
cloonix_source_dir_name="cloonix_install"
bundle=cloonix-bundle-${v_major}-${v_minor}-amd64
cloonix=$bundle.tar.gz
bookworm=bookworm.qcow2
bookworm_tar=$bookworm.gz
zipfrr=zipfrr.zip
bulk=bulk.tar.gz
profile_name=cloonix
bundle_file1=install_cloonix
bundle_file2=server.tar.gz
bundle_file3=common.tar.gz
openwrt=openwrt.qcow2
stretch=stretch.qcow2

# paths
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cloonix_source_path=$SCRIPTPATH/$cloonix_source_dir_name
bulk_path=$cloonix_source_path/opt1/cloonix_data/bulk/
cloonix_bulk_path=/var/lib/cloonix/bulk
apparmor_profiles_path=/etc/apparmor.d

# URLs
cloonix_url_root=http://clownix.net/downloads/cloonix-$v_major
cloonix_url=$cloonix_url_root/$cloonix
bookworm_tar_url=$cloonix_url_root/bulk/$bookworm_tar
zipfrr_url=$cloonix_url_root/bulk/$zipfrr
bulk_url=https://gitlab.com/amer.hasanovic/fet_net/-/raw/master/$bulk

# apparmor profile
profile_data=\
"\
# This profile allows everything and only exists to give the
# application a name instead of having the label "unconfined"

abi <abi/4.0>,
include <tunables/global>

profile cloonix /usr/libexec/cloonix/common/cloonix-hide-dirs flags=(unconfined) {
  userns,

  # Site-specific additions and overrides. See local/README for details.
  include if exists <local/cloonix>
}\
"


############
# DOWNLOAD #
############

if [ ! -d $cloonix_source_path ]; then
  mkdir $cloonix_source_dir_name
fi

cd $cloonix_source_path

if [ ! -f $cloonix_source_path/$cloonix ]; then
  echo -e "${green}Downloading Cloonix...${white}"
  wget $cloonix_url
fi

# Bookworm
if [ ! -f $cloonix_source_path/$bookworm_tar ]; then
  echo -e "${green}Downloading bookworm...${white}"
  wget $bookworm_tar_url
fi

# zipfrr
if [ ! -f $cloonix_source_path/$zipfrr  ]; then
  echo -e "${green}Downloading zipfrr...${white}"
  wget $zipfrr_url
fi

# bulk
if [ ! -f $cloonix_source_path/$bulk ]; then
  echo -e "${green}Downloading bulk...${white}"
  wget $bulk_url
fi

# gzip
installed=$(dpkg-query -W --showformat='${Status}\n' gzip | grep "install ok installed")
if [ "" = "$installed" ]; then
  echo -e "${green}Installing gzip...${white}"
  sudo apt-get --yes install gzip
fi


###########
# INSTALL #
###########

install=true

if [ ls /usr/bin/cloonix_* 1> /dev/null 2>&1 ] ||
   [ -d /usr/libexec/cloonix ] ||
   [ -d /var/lib/cloonix ]; then
  echo -ne "${yellow}Cloonix is already installed\nDo you want to reinstall it? (Y/N): ${white}"
  read uninstall

  if [[ $uninstall == [yY] || $uninstall == [yY][eE][sS] ]]; then
    echo -e "${green}Removing cloonix...${white}"
    sudo rm -rf /usr/bin/cloonix_*
    sudo rm -rf /usr/libexec/cloonix
    sudo rm -rf /var/lib/cloonix
  else
    install=false
  fi
fi

if [ $install = true ]; then
  ###########
  # EXTRACT #
  ###########

  if [ ! -f $cloonix_source_path/$bundle/$bundle_file1 ] ||
     [ ! -f $cloonix_source_path/$bundle/$bundle_file2 ] ||
     [ ! -f $cloonix_source_path/$bundle/$bundle_file3 ]; then
    echo -e "${green}Extracting cloonix bundle...${white}"
    tar -xvf $cloonix > /dev/null
  fi
  
  if [ ! -f $cloonix_source_path/$bookworm ]; then
    echo -e "${green}Extracting bookworm...${white}"
    gunzip -k $bookworm_tar
  fi
  
  if [ ! -f $bulk_path/$openwrt ] ||
     [ ! -f $bulk_path/$stretch ]; then
    echo -e "${green}Extracting bulk...${white}"
    tar -xzvf $bulk > /dev/null
  fi

  echo -e "${green}Installing cloonix...${white}"

  cd $cloonix_source_path/$bundle
  sudo ./install_cloonix > /dev/null
  cd $cloonix_source_path

  echo -e "${green}Moving bulk files...${white}"
  if [ ! -d $cloonix_bulk_path ]; then
    mkdir -p $cloonix_bulk_path
  fi

  if [ ! -f $cloonix_bulk_path/$bookworm ]; then
    sudo mv $cloonix_source_path/$bookworm $cloonix_bulk_path
  fi

  if [ ! -f $cloonix_bulk_path/$openwrt ]; then
    sudo mv $bulk_path/$openwrt $cloonix_bulk_path
  fi

  if [ ! -f $cloonix_bulk_path/$stretch ]; then
    sudo mv $bulk_path/$stretch $cloonix_bulk_path
  fi
fi

if [ -d $apparmor_profiles_path ] &&
   [ ! -f $apparmor_profiles_path/$profile_name ]; then
  echo -e "${green}Creating apparmor profile for cloonix...${white}"
  echo "$profile_data" | sudo tee -a $apparmor_profiles_path/$profile_name > /dev/null
  echo -e "${green}Reloading apparmor service...${white}"
  sudo systemctl reload apparmor.service
fi

echo -e "${yellow}Done${white}"

cd $SCRIPTPATH
