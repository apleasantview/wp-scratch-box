#!/bin/bash -
set -euo pipefail
IFS=$'\n\t'

main(){
  # set -x
  write_keys
  apache2_configuration
  apache2_restart_services
  # set +x
}

write_keys() {
  sudo openssl req -x509 -nodes -newkey rsa:4096 \
    -keyout "wp-scratch-box_root.key" \
    -out "wp-scratch-box_root.crt" \
    -days 365 \
    -subj "/C=UK/O=wp-scratch-box Improved/CN=wp-scratch-box.test"
  sudo printf "[SAN]\nsubjectAltName=DNS:wp-scratch-box.test,DNS:www.wp-scratch-box.test\n" > wp-scratch-box.test.san
  sudo openssl genrsa -out "wp-scratch-box.test.key"
  sudo openssl req -new \
    -key "wp-scratch-box.test.key" \
    -out "wp-scratch-box.test.csr" \
    -subj "/CN=wp-scratch-box.test" \
    -days 365
  sudo openssl x509 -req -extfile "wp-scratch-box.test.san" -extensions "SAN" \
    -CAcreateserial \
    -CAserial "wp-scratch-box_root.srl" \
    -CAkey "wp-scratch-box_root.key" \
    -CA "wp-scratch-box_root.crt" \
    -in "wp-scratch-box.test.csr" \
    -out "wp-scratch-box.test.crt"
}

apache2_configuration(){
  sudo mkdir /etc/apache2/ssl
  sudo mv wp-scratch-box* /etc/apache2/ssl/
  sudo cp /vagrant/resources/ssl/ssl-params.conf /etc/apache2/conf-available/
  sudo cp /vagrant/resources/ssl/default-ssl.conf.bak /etc/apache2/sites-available/default-ssl.conf
}

apache2_restart_services(){
  sudo a2enmod ssl headers
  sudo a2ensite default-ssl
  sudo a2enconf ssl-params
  sudo apache2ctl configtest
  sudo systemctl restart apache2
}

main