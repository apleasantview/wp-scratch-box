# wp-scratch-box
***v2.3.x-alpha***  

## Description
Quick Vagrant box for WordPress development, presentations, workshops, ...

## Usage
```
git clone https://github.com/apleasantview/wp-scratch-box.git
cd wp-scratch-box
vagrant up
```
Visit `http://172.16.0.12` in your browser, you will be greeted by the five minute install.

### Minimum Requirements
- [Vagrant](https://www.vagrantup.com/) ( 1.7.4 > )
- [Virtualbox](https://www.virtualbox.org/) ( 5.0 > )

### Roadmap
- Looking for contributions and input on the PHP, APACHE || `.htaccess` file and MySQL configurations.
-  ~~Setting variables from `Vagrant.json` in `wp-scratch-box.sh` for additional installation settings. Will be toying with JQ coming weeks.~~
- a VMWare provisioner for the `Vagranfile`.
- Suggestions and improvements can be discussed in the issue tracker/through PR.

## Configuration

### Vagrant.json
Vagrant configuration can be set in `Vagrant.json`. Current configuration options are:

| Config file | Vagrant | Default |
|-------------|---------|:-------:|
|"name" | "vm.define", "vm.provider.name" | wp-scratch-box |
|"vagrant_box" | "vm.box" | ubunty/trusty64 |
|"box_ip" | "vm.network" | 172.16.0.12 |
|"box_hostname"| "vm.hostname" | empty *(box default)* |

#### Synced folder
Vagrant will, on first run, create a folder named `content` which is linked with `/var/www/project/public/wp-content` inside the VM. The Host directory will be synced to `/vagrant/` per Vagrants' defaults.

### wp-scratch-box.sh
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
- **WordPress**
	- *please refer below.*

### Resources (folder)
Contains configuration files used during provisioning:  
`.htaccess` - `example.conf` - `custom-php.ini`.  
  
Files can be rewritten according to your needs.

### WordPress
Latest stable version downloaded through WP-CLI.

| Parameters | WP-CLI | Default |
|------------|--------|:-------:|
| $core_directory | --path | **.** |
| $mysql_database | --dbname | wp_dummy |
| $mysql_user | --dbuser | wp |
| $mysql_password | --dbpass | wp |
| $mysql_prefix | --dbprefix | wp_ |

#### Custom parameters
In `Vagrant.json` add the following JSON array:
```
{
  "Project": {
    ... ,
	"wordpress":[
		"$core_directory", "$mysql_database", 
		"$mysql_user", "$mysql_password", "$mysql_prefix"
	]
  }
}
```
These will be read by JQ at provisioning.

**Notes:**
- Don't forget to replace *$parameter* by your own value!
- Object for your custom parameters must be set to `"wordpress"` in `Vagrant.json`.
- Following the parameters order in the JSON array is required.
- If you change `$core_directory`, you will have to manually change the synced folder path accordingly in `Vagrantfile`.
- Default `$core_directory` is a **dot**, referencing `/var/www/project/public/$core_directory`.

#### Default folder structure
```
/var/www/project/  
+-- public/  
|	+-- .htaccess
|	+-- index.php
|	+-- wp-config.php
|	+-- wp-admin/
|	+-- wp-content/
|	+-- wp-include/
```

## Pre-packaged development environments (Multi-Machine)
By leveraging Vagrant's Multi-Machine feature, re-packaged boxes from VVV, Primary Vagrant, ... can be used in **wp-scratch-box** alongside the default `Project` VM.

### Usage
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
- The default `Project`machine will **not** start and be provisioned. You can force it to start with the command `vagrant up NAME`.
- If you run both `Project` and `Custom`, setting their IP's in the same range will create a network and facilitate communications between the two machines.
- Synced folders for the `Custom` machine needs to be currently manually set in the `Vagrantfile` if required.

***Please refer to the [Vagrant docs](https://docs.vagrantup.com/v2/multi-machine/index.html) for more info on Multi-Machine setups.***

## License
Released under the MIT license.  
*2015 - 2016 Cristovao Verstraeten*  
<br>

***Have a pleasant view!***
