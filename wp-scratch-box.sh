#!/bin/bash -
#title          :wp-scratch-box.sh
#description    :provisioning script for wp-scratch-box
#author         :Cristovao Verstraeten
#date           :20151120
#version        :2.0.0-alpha
#usage          :vagrant up --provision, vagrant provision
#notes          :
#bash_version   :4.3.39(3)-release
#============================================================================
set -euo pipefail
IFS=$'\n\t'

main() {
  # set -x
  base_packages
  additional_repos
  sudo apt-get update
  lamp_install
  wordpress
  reset_directory_permissions
  # set +x
}

base_packages() {
  sudo apt-get update && sudo apt-get install -y \
    curl \
    git-core \
    jq \
    software-properties-common \
    vim

  mkdir -p /home/vagrant/wp-cli
  (
    cd /home/vagrant/wp-cli
    curl -O -s -S https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    curl -O -s -S https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
  ) &
  printf "\n%s\n" "source /home/vagrant/wp-cli/wp-completion.bash" >> .bashrc
}

additional_repos() {
  sudo add-apt-repository -y ppa:ondrej/apache2
  sudo add-apt-repository -y ppa:ondrej/php5-5.6
}

reset_directory_permissions() {
  sudo usermod -a -G www-data vagrant
  sudo chown -R -f www-data:www-data /var/www/
  find /var/www/ -type d -print0 | sudo xargs -0 chmod -R -f 775 /var/www/
  find /var/www/ -type f -print0 | sudo xargs -0 chmod -R -f 774 /var/www/
  sudo chmod -R u+s /var/www/
  sudo chmod -R g+s /var/www/
}

lamp_install() {
  apache_install
  mysql_install
  phpfpm_install

  apache_configurations
}

apache_install() {
  sudo apt-get install -y \
    apache2
}

apache_configurations() {
  sudo apt-get install -y \
    libapache2-mod-auth-mysql
  sudo a2enmod proxy proxy_fcgi rewrite
  sudo service apache2 restart

  sudo cp /vagrant/resources/example.conf /etc/apache2/sites-available/000-default.conf
  sudo service apache2 reload
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
  ) &
}

phpfpm_install() {
  sudo apt-get install -y php5-fpm \
    php5-cli php5-mcrypt php5-mysql php5-gd php5-curl
}

wordpress() {
  # local public_directory="public"
  local core_directory="."
  local mysql_database="wp_dummy"
  local mysql_user="wp"
  local mysql_password="wp"

  mysql -u root -e "CREATE DATABASE IF NOT EXISTS $mysql_database;"
  mysql -u root -e "GRANT ALL PRIVILEGES ON $mysql_database.* TO $mysql_user@localhost IDENTIFIED BY '$mysql_password';"

  sudo chown -R -f vagrant:vagrant /var/www/
  mkdir -p "/var/www/project/public"
  (
    cd "/var/www/project/public"
    wp cli version
    wp core download --path="$core_directory/"
    wp core config --path="$core_directory/" --dbname="$mysql_database" --dbuser="$mysql_user" --dbpass="$mysql_password"
    wp core version --path="$core_directory/" --extra
  )
}

main
printf "Script finished\n"