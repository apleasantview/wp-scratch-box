#!/bin/bash -   
#title          :mailcatcher.sh
#description    :Installs MailCatcher on wp-scratch-box VM
#author         :Cristovao Verstraeten
#date           :20151202
#version        :20151202
#usage          :bash mailcatcher.sh
#notes          :       
#bash_version   :4.3.39(3)-release
#============================================================================
set -euo pipefail
IFS=$'\n\t'

main(){
    sudo apt-get install -y build-essential ruby1.9.1-dev libsqlite3-dev
    sudo gem install --no-rdoc --no-ri mailcatcher
    printf "sendmail_path = /var/lib/gems/1.9.1/gems/mailcatcher-0.6.1/bin/catchmail\n" | sudo tee /etc/php5/mods-available/mailcatcher.ini
    sudo php5enmod mailcatcher
    sudo service php5-fpm restart; sudo service apache2 restart
    mailcatcher --ip=0.0.0.0 -v
}

main