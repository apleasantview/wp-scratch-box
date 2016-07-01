#!/bin/bash -
#title          :mailcatcher.sh
#description    :Installs MailCatcher on wp-scratch-box VM
#author         :Cristovao Verstraeten
#date           :20151202
#version        :20160629
#usage          :bash mailcatcher.sh
#notes          :
#bash_version   :4.3.39(3)-release
#============================================================================
set -euo pipefail
IFS=$'\n\t'

main(){
  # set -x
  required_packages
  rbenv_ruby_install
  mailcatcher_install
  # set +x
}

required_packages(){
  sudo apt-get purge -y \
    ruby
  sudo apt-get update && sudo apt-get install -y \
    autoconf \
    bison \
    build-essential \
    libffi-dev \
    libgdbm-dev \
    libgdbm3 \
    libncurses5-dev \
    libreadline6-dev \
    libsqlite3-dev \
    libssl-dev \
    libyaml-dev \
    openssl \
    zlib1g-dev
}

rbenv_ruby_install(){
  local ruby_version="2.3.0"
  
  git clone git://github.com/sstephenson/rbenv.git /home/vagrant/.rbenv
  git clone git://github.com/sstephenson/ruby-build.git /home/vagrant/.rbenv/plugins/ruby-build
  
  (
    cd /home/vagrant/.rbenv
    src/configure
    make -C src
  )
  
  {
    echo 'export PATH=$HOME/.rbenv/bin:$PATH'
    echo 'eval "$(rbenv init -)"'
  } >> /home/vagrant/.bash_profile
  source /home/vagrant/.bash_profile

  RUBY_CONFIGURE_OPTS=--disable-install-doc rbenv install "$ruby_version"
  rbenv global "$ruby_version"
  rbenv rehash
}

mailcatcher_install(){
  gem install mailcatcher --no-document
  rbenv rehash
  mailcatcher_php
  mailcatcher_upstart
  
  mailcatcher --ip=0.0.0.0 -v
}

mailcatcher_php(){
  local mailcatcher_path
  mailcatcher_path=$(rbenv which catchmail)

  printf "sendmail_path = %s\n" "$mailcatcher_path" | sudo tee /etc/php/5.6/mods-available/mailcatcher.ini
  sudo phpenmod mailcatcher
  sudo service php5.6-fpm restart; sudo service apache2 restart
}

mailcatcher_upstart(){
  local mailcatcher_path
  local ruby_path
  mailcatcher_path=$(rbenv which mailcatcher)
  ruby_path=$(rbenv which ruby)

  cat << EOF | sudo tee /etc/init/mailcatcher.conf
description "Mailcatcher"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

exec $ruby_path $mailcatcher_path --foreground --http-ip=0.0.0.0
EOF
}

main