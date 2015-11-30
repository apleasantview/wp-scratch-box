## wp-scratch-box
***v2.0.x-alpha***  

### Description
Quick Vagrant box for WordPress development, presentations, ...

### Usage
```
git clone https://github.com/apleasantview/wp-scratch-box.git
cd wp-scratch-box
vagrant up
```
Visit `http://172.16.0.12` in your browser, you should be greeted by the five minute install.

#### Roadmap
- Looking for contributions and input on the PHP, APACHE || `.htaccess` file and MySQL configurations.
-  Setting variables from `Vagrant.json` in `wp-scratch-box.sh` for additional installation settings. Will be toying with JQ coming weeks. 
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
|"box_hostname"| *currently unused* | *(box default)* |

##### Synced folder
Vagrant will, on first run, create a folder named `content` which is linked with `/var/www/project/public/core/wp-content` inside the VM.  
The Host directory will be synced to `/vagrant/` per Vagrants' defaults

#### wp-scratch-box.sh
This is the provisioning file.
- **packages:**
    - curl
    - git-core
	- jq
	- vim
	- wp-cli w/ tab completions

- **LAMP**
	- Apache 2.4
		- Document root: `/var/www/project/public`
	- MySQL 5.5
		- root user: `root`
		- root password: `root`
	- PHP-FPM 5.6

#### Resources (folder)
Contains configuration files `.htaccess` and `example.conf`.

#### WordPress
- Latest version (downloaded through WP-CLI)  

##### Folder structure
```
.project  
+-- public  
|	+-- .htaccess
|	+-- index.php
|	+-- wp-config.php
|	+-- wp-admin/
|	+-- wp-content/
|	+-- wp-include/
|	+-- (wp core files)
```
~~The wp-config file can be overridden by placing a `site-conf.php` file in the `project` directory. See https://github.com/cristovaov/wp-sample-config for an example.~~  
***v2.0.x-alpha: Removed in favor of WP-CLI commands.***

##### MySQL
- user: `wp`
- password: `wp`
- database name: `wp_dummy`  

These values can currently be manually changed in `wp-scratch-box.sh`.  
Be sure to change these values in `wp-config.php` after provisioning.

### Pre-packaged development environments (Multi-Machine)
By leveraging Vagrant's Multi-Machine feature, re-packaged boxes from VVV, Primary Vagrant, ... can be used in **wp-scratch-box** alongside the default `Project` VM.

#### Usage
In `Vagrant.json` append the following Parent Object:
```
{
  "Project": {
    ...
  },
  "Custom": {
    "name": "test",
    "vagrant_box": "ubuntu/trusty64",
    "box_ip": "172.16.0.13",
    "box_hostname": ""
  }
}
```
Follow with command `vagrant up`  

**Notes:** 
- All keys are required and Parent Object must be set to `"Custom"` in `Vagrant.json`.
- The default `Project`machine will **not** start and be provisioned. You can force it to start with the command `vagrant up NAME`
- If you run both `Project` and `Custom`, setting their IP's in the same range will create a network and facilitate communications between the two machines.  
- Synced folders for the `Custom` machine needs to be currently manually set in the `Vagrantfile` if required.

***Please refer to the [Vagrant docs](https://docs.vagrantup.com/v2/multi-machine/index.html) for more info on Multi-Machine setups.***  
<br>

### License
Released under the MIT license.  
*2015 - Cristovao Verstraeten*  
<br>

***Have a pleasant view!***