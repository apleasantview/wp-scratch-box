## wp-scratch-box
***v1.0.x-alpha***  

### Description
Quick Vagrant box for WordPress development, presentations, ...

### Usage
`git clone https://github.com/apleasantview/wp-scratch-box.git`  
`vagrant up`  

Visit `http://172.16.0.12` in your browser, you should be greeted by the five minute install.

#### Roadmap
- Looking for contributions and input on the PHP, APACHE || `.htaccess` file and MySQL configurations.
-  Setting variables from `Vagrant.json` in `wp-scatch-box.sh` for additional installation settings. Will be toying with JQ coming weeks. 
- a VMWare provisioner for the `Vagranfile`.
- Suggestions can be discussed in the issue tracker/through PR.  
</br>

### Minimum Requirements
- [Vagrant](https://www.vagrantup.com/) ( 1.7.4 > )
- [Virtualbox](https://www.virtualbox.org/) ( 5.0 > )

### Configuration

#### Vagrant.json
Vagrant configuration can be set in `Vagrant.json`.
Current configuration options:

| Config file | Vagrant | Default |
|-------------|---------|---------|
|"name" | "vm.define", "vm.provider.name" | wp-scratch-box |
|"vagrant_box" | "vm.box" | ubunty/trusty64 |
|"box_ip" | "vm.network" | 172.16.0.12 |
|"box_hostname"| *unused* | (empty) |

##### Synced folder
Vagrant will, at the first run, create a folder named `content` which is linked with `/var/www/project/public/core/wp-content` inside the VM.

#### wp-scratch-box.sh
This is the provisioning file.
- **packages:**
    - curl
    - git-core
	- jq
	- vim
	- wp-cli

#### LAMP
- Apache 2.4
	- Document root: `/var/www/project/public`
- MySQL 5.5
	- root user: `root`
	- root password: `root`
- PHP-FPM 5.6

#### Resources (folder)
Contains configuration files `.htacces` and `example.conf`.

#### WordPress
- Latest version (downloaded through WP-CLI)  

##### Folder structure
```
.project  
+-- public  
|	+-- .htaccess
|   +-- index.php
|	+-- wp-config.php
|   +-- core
|		+-- (wp core files)
|		+-- wp-admin
|		+-- wp-content
|		+-- wp-include
```
The wp-config file can be overridden by placing a `site-conf.php` file in the `project` directory. See https://github.com/cristovaov/wp-sample-config for an example.

##### MySQL
- user: `wp`
- password: `wp`
- database name: `wp_dummy`  

These values can currently be changed in `wp-scratch-box.sh`.

<br>

### License
Released under the MIT license.  
*2015 - Cristovao Verstraeten*  
<br>

***Have a pleasant view!***