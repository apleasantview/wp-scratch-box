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

PHPVERSION=${PHPVERSION:-"8.1"}

main() {
  # set -x
  base_packages
  lamp_install
  memcached_install
  mailpit_install
  composer_install
  wpcli_install
  wordpress

  if [ -d "/home/vagrant/public" ];
    then
      echo "Symlink exists."
    else
      ln -s /var/www/public/ public
  fi
  # set +x
}

base_packages() {
  echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections
  sudo apt-get update && sudo apt-get install -y -qq \
    apt-transport-https \
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
}

lamp_install() {
  apache_install
  mariadb_install
  phpfpm_install

  # Post LAMP installation.
  apache_configurations
}

apache_install() {
  # Add repository.
  sudo add-apt-repository ppa:ondrej/apache2

  # Update apt source and install quietly.
  sudo apt-get update && sudo apt-get install -y -qq \
    apache2
}

apache_configurations() {
  sudo a2enmod expires headers proxy proxy_fcgi rewrite setenvif
  sudo a2enconf php${PHPVERSION}-fpm
  sudo service apache2 restart

  sudo cp /vagrant/resources/apache/wp-scratch-box.conf /etc/apache2/sites-available/000-default.conf
  sudo service apache2 reload

  sudo usermod -a -G www-data vagrant
}

mariadb_install() {
  local root_password="root"

  # First import the release signing key.
  sudo mkdir -p /etc/apt/keyrings
  sudo curl -o /etc/apt/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'

  # Add source file.
  sudo cp /vagrant/resources/mariadb/mariadb.sources /etc/apt/sources.list.d/mariadb.sources

  # Set default password.
  echo "maria-db-10.6 mysql-server/root_password password $root_password" | sudo debconf-set-selections
  echo "maria-db-10.6 mysql-server/root_password_again password $root_password" | sudo debconf-set-selections

  # Update apt source and install quietly.
  sudo apt-get update && sudo apt-get install -y -qq mariadb-server

  # Revert to the old mysql_native_password authentication method. Needed from 10.4 on.
  local revert_auth=$( cat <<-SQL
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password USING PASSWORD('root');
FLUSH PRIVILEGES;
SQL
  )
  sudo mysql -u root -proot -e "${revert_auth}"

  # Run MySQL without passwords for convenience.
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
  # Add repository.
  sudo add-apt-repository ppa:ondrej/php

  # Update apt source and install quietly.
  sudo apt-get update && sudo apt-get install -y -qq php${PHPVERSION}-fpm \
    php${PHPVERSION}-cli php${PHPVERSION}-common php${PHPVERSION}-bcmath php${PHPVERSION}-curl \
    php${PHPVERSION}-gd php${PHPVERSION}-imagick php${PHPVERSION}-imap php${PHPVERSION}-intl \
    php${PHPVERSION}-mbstring php${PHPVERSION}-mysql php${PHPVERSION}-pcov php${PHPVERSION}-soap \
    php${PHPVERSION}-ssh2 php${PHPVERSION}-xdebug php${PHPVERSION}-xml php${PHPVERSION}-xmlrpc php${PHPVERSION}-zip php-pear \
    php${PHPVERSION}-memcache php${PHPVERSION}-memcached

  sudo cp /vagrant/resources/php/php-fpm.conf /etc/php/${PHPVERSION}/fpm/php-fpm.conf
  sudo cp /vagrant/resources/php/pool-www.conf /etc/php/${PHPVERSION}/fpm/pool.d/www.conf
  sudo cp /vagrant/resources/php/custom-php.ini /etc/php/${PHPVERSION}/fpm/conf.d/php-custom.ini
  sudo cp /vagrant/resources/php/opcache.ini /etc/php/${PHPVERSION}/fpm/conf.d/opcache.ini
  sudo cp /vagrant/resources/php/mailpit.ini /etc/php/8.1/mods-available/mailpit.ini

  # sudo phpenmod custom-php
  sudo phpenmod mailpit

  sudo phpdismod xdebug
  sudo phpdismod pcov

  # Explicitly restart PHP.
  sudo service php${PHPVERSION}-fpm restart &> /dev/null
}

memcached_install() {
  # Update apt source and install quietly.
  sudo apt-get update && sudo apt-get install -y -qq memcached

  # Copy memcached configuration.
  sudo cp /vagrant/resources/memcached/memcached.conf /etc/memcached.conf

  # Restart memcached service.
  sudo systemctl restart memcached
}

mailpit_install() {
  sudo bash < <(curl -sL https://raw.githubusercontent.com/axllent/mailpit/develop/install.sh)

  (
    sudo cat << 'EOF' | sudo tee /etc/systemd/system/mailpit.service
[Unit]
Description=Mailpit
After=network.target

[Service]
User=vagrant
ExecStart=/usr/bin/env /usr/local/bin/mailpit -- > /dev/null 2>&1 &

[Install]
WantedBy=multi-user.target
EOF
  )

  sudo systemctl enable --now mailpit
}

composer_install() {
  curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
  composer --version

  # Fix 'permission denied' with vagrant-cachier symlink.
  if [ -d "/home/vagrant/.composer" ];
    then
      composer --version
      echo "Composer directory exists."
    else
      mkdir /home/vagrant/.composer
      sudo chown -R vagrant:vagrant /home/vagrant/.composer
  fi
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

wpcli_error_handler() {
  printf "WordPress files seem to already be present here. Moving on...\n"
  exit 0
}

wordpress() {
  local parser
  parser=$(jq -r 'if .Project.wordpress then .Project.wordpress|to_entries|map("\(.key)=\(.value|tostring)")| .[] else empty end' /vagrant/wp-scratch-box.json)

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
printf "\tVisit http://192.168.56.4 for the 5 minute install!\n"
printf "\tIf you would like to access the site from a custom URL, add it to your hosts file.\n"
printf "\t\tHave a pleasant view!\n"
echo " "
