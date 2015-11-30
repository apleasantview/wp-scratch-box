# -*- mode: ruby -*-
# # vi: set ft=ruby :
dir = File.dirname(File.expand_path(__FILE__))

require 'json'
json = File.read("#{dir}/Vagrant.json")
set = JSON.parse(json)
alt_box = set.has_key?("Custom")

Vagrant.configure(2) do |config|
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
  config.vm.define set['Project']['name'] do |project|
    project.vm.box = set['Project']['vagrant_box']
    project.vm.provider "virtualbox" do |vb|
      vb.name = set['Project']['name']
    end
    project.vm.network "private_network", ip: set['Project']['box_ip']
    project.vm.provision "shell", path: "wp-scratch-box.sh", privileged: false
    project.vm.synced_folder "content/", "/var/www/project/public/wp-content/", create: true,
      owner: "www-data", group: "www-data"
  end
  
  if alt_box == true
    config.vm.define set['Project']['name'], autostart: false
    config.vm.define set['Custom']['name'] do |custom|
      custom.vm.box = set['Custom']['vagrant_box']
      custom.vm.provider "virtualbox" do |vb|
        vb.name = set['Custom']['name']
      end
      custom.vm.network "private_network", ip: set['Custom']['box_ip']
    end  
  end
end
