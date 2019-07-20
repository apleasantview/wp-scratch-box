# wp-scratch-box
![GitHub tag (latest by date)](https://img.shields.io/github/tag-date/apleasantview/wp-scratch-box.svg?label=release) [![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)

## Description
A quick and disposable Vagrant box for WordPress.   
It is suitable for a range of activities like presentations, workshops and development.
> 🎉 v5.0.0!   
This release mainly aims to improve the user experience of this tool. Configuration is more explicit for verbosity and the documentation revised. Releases are now prefixed and comes paired with a generated changelog.

## Table of Contents 🔖
- [Usage](#usage)
  * [Minimum Requirements](#minimum-requirements)
- [Configuration](#configuration)
  * [Vagrant](#vagrant)
    + [Vagrant.json](#vagrantjson)
      - [Synced folder](#synced-folder)
    + [Provisioning](#provisioning)
  * [WordPress Configuration](#wordpress-configuration)
    + [Optional parameters](#optional-parameters)
    + [Default folder structure](#default-folder-structure)
  * [Resources (folder)](#resources--folder-)
  * [Vagrant plugins](#vagrant-plugins)
- [Vagrant Multi-Machine](#vagrant-multi-machine)
  * [Multi-Machine Configuration](#multi-machine-configuration)
- [Roadmap](#roadmap)
- [License](#license)

## Usage ⌨️
```
git clone https://github.com/apleasantview/wp-scratch-box.git
cd wp-scratch-box
vagrant up
```
Visit `http://172.16.0.12` in your browser, you will be greeted by the five minute install - It's that easy! If you need a little bit more then read on below for details and configuration of your own `wp-scratch-box`.

### Minimum Requirements
- [Vagrant](https://www.vagrantup.com/) ( 1.7.4 > )
- [Virtualbox](https://www.virtualbox.org/) ( 5.0 > )

## Configuration 🔧
### Vagrant
#### Vagrant.json
Vagrant configuration can be set in `Vagrant.json`. Current configuration options are:

| Config key | Vagrant setting | Default |
|-------------|---------|-------:|
| "name" | "vm.define", "vm.provider.name" | wp-scratch-box |
| "vagrant_box" | "vm.box" | ubuntu/bionic64 |
| "box_ip" | "vm.network" | 172.16.0.12 |
| "box_hostname" | "vm.hostname" | wp-scratch-box.test |
| "vb_cpus" | "vb.cpus" | 2 |
| "vb_memory" | "vb.memory" | 1024 |
| "vb_linked_clone" | "vb.linked_clone" | true |
| "synced_folder" | "vm.synced_folder"| <i>see below</i> |

##### Synced folder
| "synced_folder" | path |
| --------------- |:----:|
| "host_path" | "src/" |
| "guest_path" | "/var/www/public" |

Vagrant will create the `host_path` folder if it doesn't exist. The root Host directory will be synced to `/vagrant` per Vagrants' defaults. Note that there is no '/' at the end of the `guest_path`.

#### Provisioning
`wp-scratch-box.sh`  
This is the provisioning file that will install the following packages and LAMP stack:
- **packages:**
  - composer
  - curl
  - git-core
  - imagemagick
  - jq
  - ntp
  - software-properties-common
  - unzip
  - vim
  - zip
  - wp-cli w/ tab completions
- **LAMP**
	- Apache 2.4
		- Document root: `/var/www/public`
	- MariaDB 10.3
		- root user: `root`
		- root password: `root`
	- PHP-FPM 7.2
- **WordPress**
	- *See below*

### WordPress Configuration
The latest stable version of WordPress is downloaded and configured through WP-CLI.

In `Vagrant.json` modify the values of the `wordpress` object:
```json
{
  "Project": {
    "vagrant": {
      // vagrant config
    },
    "wordpress": {
      "mysql_database": "wp_dummy",
      "mysql_user": "wp",
      "mysql_password": "wp",
      "mysql_prefix": "wp_"
    }
  }
}
```
These will be read by the [jq utility](https://stedolan.github.io/jq/) at provisioning and passed on to WP-CLI and the `mysql` command to set up your database.

#### Optional parameters
The `root_directory` and `core_directory` parameters are completely optional. These are mostly used in an advanced setup where WP Core is installed in its own directory. See this [Codex page](https://wordpress.org/support/article/giving-wordpress-its-own-directory/) for more info. 

Below is a table with how the parameters relate to configuration and WP-CLI:

| Parameters | WP-CLI | Default | Set in Vagrant.json |
|:-----------|:------:|:-------:|---:|
| root_directory | *not used* | public | optional |
| core_directory | --path | **.** | optional |
| mysql_database | --dbname | wp_dummy | required |
| mysql_user | --dbuser | wp | required |
| mysql_password | --dbpass | wp | required |
| mysql_prefix | --dbprefix | wp_ | required |

**⚠️ Warning:**  
If you should change the `root_directory` and `core_directory` parameters:
- Make sure `guest_path` is set accordingly in the `vagrant` configuration part of `Vagrant.json`.
- You will need to change paths in the apache configuration `wp-scratch-box.conf` in the `resources` folder.
- Do not put a '/' at the front or end of these values.

#### Default folder structure
```
/var/www/  
+-- public/  
|	+-- .htaccess
|	+-- index.php
|	+-- wp-config.php
|	+-- wp-admin/
|	+-- wp-content/
|	+-- wp-include/
```
### Resources (folder)
Contains configuration files used during provisioning for Apache and PHP:  
`.htaccess` - `wp-scratch-box.conf` - `custom-php.ini`.
  
Please review these files and make adjustments accordingly if you change any default configuration values.

~~The `resources` folder also has a Mailcatcher installation script.~~ *Mailcatcher is deprecated. The script is still present but unlikely to work. It will be removed in the future for sure.*

### Vagrant plugins
If you have `vagrant-cachier` installed, the config in the Vagrantfile is set to cache by machine.
If you have `vagrant-vbguest` installed, guest additions updates is set to `false`. Manually update guest additions if really needed.

## Vagrant Multi-Machine ⚒️
<small>***for advanced users***</small>   
By leveraging Vagrant's Multi-Machine feature, you can hook up an additional virtual machine or re-packaged boxes from VVV, Primary Vagrant, etc. alongside the main `Project` VM.

### Muti-Machine Configuration
In `Vagrant.json` append the following Parent Object:
```json
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

## Roadmap
- Open to any sort of contributions.
- Suggestions and improvements can be discussed in the issue tracker/through PR.

## License
Released under the MIT license.  
*2015 - 2019 a pleasant view | Cristovao Verstraeten*  
<br>

***Have a pleasant view!***
