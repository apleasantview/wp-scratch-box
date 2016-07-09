#!/bin/bash -
#title          :wp-scratch-box.sh
#description    :provisioning script for wp-scratch-box
#author         :Cristovao Verstraeten
#date           :20151120
#version        :2.10.7
#usage          :vagrant up --provision, vagrant provision
#notes          :
#bash_version   :4.3.39(3)-release
#============================================================================
set -euo pipefail
IFS=$'\n\t'

main() {
  # set -x
  additional_repos
  base_packages
  lamp_install
  wp_custom=($(jq -r 'if .Project.wordpress then .Project.wordpress|.[] else empty end' /vagrant/Vagrant.json))
  wordpress
  # set +x
}

additional_repos() {
  sudo add-apt-repository -y ppa:ansible/ansible
  sudo add-apt-repository -y ppa:ondrej/apache2
  sudo add-apt-repository -y ppa:ondrej/php
}

base_packages() {
  sudo apt-get update && sudo apt-get install -y \
    ansible \
    curl \
    git-core \
    jq \
    software-properties-common \
    vim

  cp /home/vagrant/.profile /home/vagrant/.bash_profile
  wpcli_install
}

wpcli_install() {
  mkdir -p /home/vagrant/wp-cli
  (
    cd /home/vagrant/wp-cli
    curl -O -s -S https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    curl -O -s -S https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
  )
  printf "\n%s\n" "source /home/vagrant/wp-cli/wp-completion.bash" >> .bash_profile
}

lamp_install() {
  apache_install
  mysql_install
  phpfpm_install

  apache_configurations
}

apache_install() {
  sudo apt-get install -y \
    apache2 \
    libapache2-mod-auth-mysql \
    libapache2-mod-php5.6
}

apache_configurations() {
  sudo a2enmod proxy proxy_fcgi rewrite setenvif
  sudo a2enconf php5.6-fpm
  sudo service apache2 restart

  sudo cp /vagrant/resources/example.conf /etc/apache2/sites-available/000-default.conf
  sudo service apache2 reload

  sudo usermod -a -G www-data vagrant
}

mysql_install() {
  local root_password="root"

  echo "mysql-server-5.5 mysql-server/root_password password $root_password" | sudo debconf-set-selections
  echo "mysql-server-5.5 mysql-server/root_password_again password $root_password" | sudo debconf-set-selections
  sudo apt-get install -y mysql-server-5.5

  # Run MySQL without passwords for convenience
  (
    cat << 'EOF' | tee /home/vagrant/.my.cnf
[client]
user     = root
password = root

[mysqladmin]
user     = root
password = root
EOF
  )
}

phpfpm_install() {
  sudo apt-get install -y php5.6-fpm \
    php5.6-cli php5.6-mcrypt php5.6-mysql php5.6-gd php5.6-curl
  sudo cp /vagrant/resources/custom-php.ini /etc/php/5.6/mods-available/
  sudo phpenmod custom-php
  
  # explicitly restart php
  sudo service php5.6-fpm restart &> /dev/null
}

wpcli_error_handler() {
  printf "WordPress files seem to already be present here. Moving on...\n"
  exit 0
}

wordpress() {
  local public_directory=${wp_custom[0]:-public}
  local core_directory=${wp_custom[1]:-.}
  local mysql_database=${wp_custom[2]:-wp_dummy}
  local mysql_user=${wp_custom[3]:-wp}
  local mysql_password=${wp_custom[4]:-wp}
  local mysql_prefix=${wp_custom[5]:-wp_}

  mysql -u root -e "CREATE DATABASE IF NOT EXISTS $mysql_database;"
  mysql -u root -e "GRANT ALL PRIVILEGES ON $mysql_database.* TO $mysql_user@localhost IDENTIFIED BY '$mysql_password';"

  mkdir -p "/var/www/project/$public_directory"
  (
    trap 'wpcli_error_handler' ERR

    cd "/var/www/project/$public_directory"
    wp cli version
    wp core download --path="$core_directory/" 2> /dev/null
    wp core config --path="$core_directory/" --dbname="$mysql_database" --dbuser="$mysql_user" --dbpass="$mysql_password" --dbprefix="$mysql_prefix"
    wp core version --path="$core_directory/" --extra
  )
}

main
echo " "
printf "Provisioning script finished without errors.\nHave a pleasant view!\n"
