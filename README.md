# wp-scratch-box
***v3.1.x***  

## Description
Quick Vagrant box for WordPress. Configurable and with support for Vagrant Multi-Machine.   
Suitable for presentations, workshops, ... and minor development.   


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
- v3.x.x: moving provisioning to Ansible, PHP version bump, MariaDB, ...
- Looking for contributions and input on the PHP, APACHE || `.htaccess` file and MySQL configurations.
- A VMWare provisioner for the `Vagranfile`.
- Suggestions and improvements can be discussed in the issue tracker/through PR.

## Vagrant Configuration

### Vagrant.json
Vagrant configuration can be set in `Vagrant.json`. Current configuration options are:

| Config file | Vagrant | Default |
|-------------|---------|:-------:|
| "name" | "vm.define", "vm.provider.name" | wp-scratch-box |
| "vagrant_box" | "vm.box" | ubunty/trusty64 |
| "box_ip" | "vm.network" | 172.16.0.12 |
| "box_hostname" | "vm.hostname" | wp-scratch.box |
| "vb_cpus" | "vb.cpus" | 2 |
| "vb_memory" | "vb.memory" | 1024 |
| "vb_linked_clone" | "vb.linked_clone" | true |
| "synced_folder" | "vm.synced_folder"| <i>see below</i> |

#### Synced folder
| "synced_folder" | path |
| --------------- |:----:|
| "host_path" | "project/" |
| "guest_path" | "/var/www/project/public" |

Vagrant will create the `host_path` folder if it doesn't exist. The main Host directory will be synced to `/vagrant` per Vagrants' defaults.

### Vagrant plugins
if you have vagrant-cachier installed, the config in the Vagrantfile is set to cache by machine.

### wp-scratch-box.sh
This is the provisioning file.
- **packages:**
  - ansible
  - composer
  - curl
  - git-core
  - jq
  - ntp
  - software-properties-common
  - unzip
  - vim
  - zip
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
Contains configuration files used during provisioning for Apache and PHP:  
`.htaccess` - `example.conf` - `custom-php.ini`.
  
Please review these files and make adjustments accordingly if you change any default configuration values.

**Note:** Instead of rewriting these files, the use of Ansible playbooks after the initial provisioning is preferred. Equally, using Ansible to add any other packages or modules is encouraged.

The `resources` folder also has a Mailcatcher installation script.

## WordPress Configuration
Latest stable version downloaded through WP-CLI.

| Parameters | WP-CLI | Default |
|------------|--------|:-------:|
| $public_directory | *core parent directory* | public |
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
		"$public_directory",
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
- If you change `$public_directory` `$core_directory`, set the synced folder path accordingly in `Vagrant.json` and vice-versa.
- Default `$public_directory` refers to `/var/www/project/$public_directory`.
- Default `$core_directory` is a **dot**, referencing `/var/www/project/$public_directory/$core_directory`.

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

## Mailcatcher: mailcatcher.sh
You can install [Mailcatcher](https://mailcatcher.me/) with the prodived installation script in the `resources` folder. Mailcatcher is configured to start at boot.   
Mailcatcher address (w/ the default configuration IP): `http://172.16.0.12:1080/`

### Installation
```
(host-machine)$ vagrant ssh
(guest-machine)$ bash /vagrant/resources/mailcatcher.sh
```
  
## Pre-packaged development environments (Multi-Machine)
By leveraging Vagrant's Multi-Machine feature, re-packaged boxes from VVV, Primary Vagrant, ... can be used in **wp-scratch-box** alongside the main `Project` VM.

For this use case, the main project serves as a sort of local staging environment. Pre-packaged boxes more resembling your production environment can also be used. Modify `vagrant_box` in the json file and run `vagrant up NAME --no provision`.

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
- If you run both `Project` and `Custom`, setting their IP's in the same range will create a network and facilitate communication between the two machines.
- Synced folders for the `Custom` machine needs to be manually set in the `Vagrantfile` if required.

***Please refer to the [Vagrant docs](https://docs.vagrantup.com/v2/multi-machine/index.html) for more info on Multi-Machine setups.***

## License
Released under the MIT license.  
*2015 - 2016 Cristovao Verstraeten*  
<br>

***Have a pleasant view!***