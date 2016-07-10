# -*- mode: ruby -*-
# # vi: set ft=ruby :
dir = File.dirname(File.expand_path(__FILE__))

require 'json'
json = File.read("#{dir}/Vagrant.json")
set = JSON.parse(json)
alt_box = set.has_key?("Custom")

Vagrant.configure(2) do |config|
  config.ssh.forward_agent = true
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
  config.vm.define set['Project']['name'] do |project|
    project.vm.box = set['Project']['vagrant_box']
    if !set['Project']['box_hostname'].empty?
      project.vm.hostname= set['Project']['box_hostname']
    end
    project.vm.provider "virtualbox" do |vb|
      vb.name = set['Project']['name']
      vb.cpus = set['Project']['vb_cpus']
      vb.memory = set['Project']['vb_memory']
    end
    project.vm.network "private_network", ip: set['Project']['box_ip']
    project.vm.provision "shell", path: "wp-scratch-box.sh", privileged: false
    project.vm.synced_folder set['Project']['synced_folder']['host_path'], set['Project']['synced_folder']['guest_path'],
      create: true, owner: "vagrant", group: "www-data", :mount_options => ['dmode=775', 'fmode=664']
  end

  if alt_box == true
    config.vm.define set['Project']['name'], autostart: false
    config.vm.define set['Custom']['name'] do |custom|
      custom.vm.box = set['Custom']['vagrant_box']
      if !set['Custom']['box_hostname'].empty?
        custom.vm.hostname= set['Custom']['box_hostname']
      end
      custom.vm.provider "virtualbox" do |vb|
        vb.name = set['Custom']['name']
        vb.cpus = set['Custom']['vb_cpus']
        vb.memory = set['Custom']['vb_memory']
      end
      custom.vm.network "private_network", ip: set['Custom']['box_ip']
    end
  end
end
