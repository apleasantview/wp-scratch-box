# -*- mode: ruby -*-
# # vi: set ft=ruby :
dir = File.dirname(File.expand_path(__FILE__))

require 'json'
json = File.read("#{dir}/wp-scratch-box.json")
parser = JSON.parse(json)
set = parser['Project']
alt_box = parser.has_key?("Custom")

ENV["LC_ALL"] = "en_US.UTF-8"

Vagrant.configure("2") do |config|
  config.ssh.forward_agent = true
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
  config.vm.define set['vagrant']['name'] do |project|
    project.vm.box = set['vagrant']['vagrant_box']
    if !set['vagrant']['box_hostname'].empty?
      project.vm.hostname= set['vagrant']['box_hostname']
    end
    project.vm.provider "virtualbox" do |vb|
      vb.name = set['vagrant']['name']
      vb.cpus = set['vagrant']['vb_cpus']
      vb.memory = set['vagrant']['vb_memory']
      vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
      vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
      vb.customize ['modifyvm', :id, '--ostype', 'Ubuntu_64']
      vb.customize ['modifyvm', :id, '--cableconnected1', 'on']
      vb.linked_clone = set['vagrant']['vb_linked_clone']
    end
    project.vm.network "private_network", ip: set['vagrant']['box_ip']
    project.vm.provision "shell", path: "wp-scratch-box.sh", privileged: false
    project.vm.synced_folder set['vagrant']['synced_folder']['host_path'], set['vagrant']['synced_folder']['guest_path'],
      create: true, owner: "vagrant", group: "www-data", :mount_options => ['dmode=775', 'fmode=664']
  end

  if alt_box == true
    alt = parser['Custom']
    config.vm.define set['vagrant']['name'], autostart: false
    config.vm.define alt['vagrant']['name'] do |custom|
      custom.vm.box = alt['vagrant']['vagrant_box']
      if !alt['vagrant']['box_hostname'].empty?
        custom.vm.hostname= alt['vagrant']['box_hostname']
      end
      custom.vm.provider "virtualbox" do |vb|
        vb.name = alt['vagrant']['name']
        vb.cpus = alt['vagrant']['vb_cpus']
        vb.memory = alt['vagrant']['vb_memory']
        vb.linked_clone = alt['vagrant']['vb_linked_clone']
      end
      custom.vm.network "private_network", ip: alt['vagrant']['box_ip']
    end
  end
  
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :machine
  end

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end
end
