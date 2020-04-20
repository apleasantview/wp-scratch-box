#!/bin/bash -
#title          :wp-scratch-box.sh
#description    :provisioning script for wp-scratch-box
#author         :Cristovao Verstraeten
#date           :20151120
#version        :see CHANGELOG.md
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
  composer_install
  wordpress
  # set +x
}

additional_repos() {  
  # MariaDB
  sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
  sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://ftp.nluug.nl/db/mariadb/repo/10.3/ubuntu bionic main'
}

base_packages() {
  echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections
  sudo apt-get update && sudo apt-get install -y \
    curl \
    git-core \
    imagemagick \
    jq \
    ntp \
    software-properties-common \
    unzip \
    vim \
    zip

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
  mariadb_install
  phpfpm_install

  apache_configurations
}

apache_install() {
  sudo apt-get install -y \
    apache2
}

apache_configurations() {
  sudo a2enmod expires headers proxy proxy_fcgi rewrite setenvif
  sudo a2enconf php7.2-fpm
  sudo service apache2 restart

  sudo cp /vagrant/resources/wp-scratch-box.conf /etc/apache2/sites-available/000-default.conf
  sudo service apache2 reload

  sudo usermod -a -G www-data vagrant
}

mariadb_install() {
  local root_password="root"

  echo "maria-db-10.3 mysql-server/root_password password $root_password" | sudo debconf-set-selections
  echo "maria-db-10.3 mysql-server/root_password_again password $root_password" | sudo debconf-set-selections
  sudo apt-get install -y mariadb-server

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
  sudo apt-get install -y php7.2-fpm \
    php7.2-cli php7.2-common php7.2-bcmath php7.2-curl \
    php7.2-gd php7.2-imap php7.2-json php7.2-mbstring php7.2-mysql php7.2-soap \
    php7.2-xml php7.2-xmlrpc php7.2-zip php-imagick php-pear
  sudo cp /vagrant/resources/custom-php.ini /etc/php/7.2/mods-available/
  sudo phpenmod custom-php
  
  # explicitly restart php
  sudo service php7.2-fpm restart &> /dev/null
}

composer_install() {
  curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
  composer --version
  
  # fix 'permission denied' with vagrant-cachier symlink
  sudo chown -R vagrant:vagrant /home/vagrant/.composer
}

wpcli_error_handler() {
  printf "WordPress files seem to already be present here. Moving on...\n"
  exit 0
}

wordpress() {
  local parser
  parser=$(jq -r 'if .Project.wordpress then .Project.wordpress|to_entries|map("\(.key)=\(.value|tostring)")| .[] else empty end' /vagrant/Vagrant.json)
  
  declare -A wp_custom
  while IFS="=" read -r key value; do
    wp_custom[$key]="$value";
  done < <(echo "$parser")

  local root_directory=${wp_custom[root_directory]:-public}
  local core_directory=${wp_custom[core_directory]:-.}
  local mysql_database=${wp_custom[mysql_database]:-wp_dummy}
  local mysql_user=${wp_custom[mysql_user]:-wp}
  local mysql_password=${wp_custom[mysql_password]:-wp}
  local mysql_prefix=${wp_custom[mysql_prefix]:-wp_}

  mysql -u root -e "CREATE DATABASE IF NOT EXISTS $mysql_database;"
  mysql -u root -e "GRANT ALL PRIVILEGES ON $mysql_database.* TO $mysql_user@localhost IDENTIFIED BY '$mysql_password';"

  mkdir -p "/var/www/$root_directory"
  (
    trap 'wpcli_error_handler' ERR

    cd "/var/www/$root_directory"
    wp cli version
    wp core download --path="$core_directory/" 2> /dev/null
    wp core config --path="$core_directory/" --dbname="$mysql_database" --dbuser="$mysql_user" --dbpass="$mysql_password" --dbprefix="$mysql_prefix"
    wp core version --path="$core_directory/" --extra
  )
}

main

printf "\n========\n"
printf "\n\tProvisioning script finished without errors.\n"
printf "\tVisit http://172.16.0.12 for the 5 minute install!\n"
printf "\t\tHave a pleasant view!\n"
echo " "
