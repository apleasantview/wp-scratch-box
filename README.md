# wp-scratch-box
![GitHub tag (latest by date)](https://img.shields.io/github/tag-date/apleasantview/wp-scratch-box.svg?label=release) [![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)

## ℹ️ Description
A quick and disposable Vagrant box for WordPress.   
It is suitable for a range of activities like presentations, workshops and development.

---

## 🔖 Table of Contents
- [Usage](#usage)
  * [Minimum Requirements](#minimum-requirements)
- [Provisioning](#provisioning)
  * [wp-scratch-box.sh](#wp-scratch-boxsh)
- [Configuration](#configuration)
  * [Vagrant.json](#vagrantjson)
    + [Default Vagrant configuration](#default-vagrant-configuration)
      - [Synced folder object:](#synced-folder-object-)
  * [WordPress Configuration](#wordpress-configuration)
    + [Default WordPress configuration](#default-wordpress-configuration)
    + [Optional parameters](#optional-parameters)
  * [LAMP default directory structure](#lamp-default-directory-structure)
  * [Resources (directory)](#resources--directory-)
  * [Database (directory)](#database--directory-)
  * [Scripts (directory)](#scripts--directory-)
  * [Vagrant plugins](#vagrant-plugins)
- [Configuration Warning](#configuration-warning)
- [Advanced Configuration](#advanced-configuration)
  * [Vagrant Multi-Machine](#vagrant-multi-machine)
    + [Muti-Machine configuration](#muti-machine-configuration)
  * [Multi-Machine Warning](#multi-machine-warning)
- [Contribute to `wp-scratch-box`](#contribute-to--wp-scratch-box-)
- [License](#license)

---

## ⌨️ Usage
```
git clone https://github.com/apleasantview/wp-scratch-box.git
cd wp-scratch-box
vagrant up
```
Visit `http://172.16.0.12` in your browser, you will be greeted by the five minute install - It's that easy! If you need a little bit more then read on below for details and configuration of your own `wp-scratch-box`.

### Minimum Requirements
- [Vagrant](https://www.vagrantup.com/) ( 1.7.4 > )
- [Virtualbox](https://www.virtualbox.org/) ( 5.0 > )

## 📜 Provisioning
### wp-scratch-box.sh
This is the provisioning file that will install the following packages and LAMP stack:
- **Packages:**
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
  - Apache2
  - MariaDB 10.6
  - PHP-FPM 8.0
- **WordPress**
  - Latest stable version downloaded with WP-CLI.

##  🔧 Configuration
### Vagrant.json
Vagrant configuration can be modified in `Vagrant.json`, inside the `vagrant` object.

#### Default Vagrant configuration
| Config key | Vagrant setting | Default |
|-------------|---------|-------:|
| "name" | "vm.define", "vm.provider.name" | wp-scratch-box |
| "vagrant_box" | "vm.box" | ubuntu/bionic64 |
| "box_ip" | "vm.network" | 172.16.0.12 |
| "box_hostname" | "vm.hostname" | wp-scratch-box.test |
| "vb_cpus" | "vb.cpus" | 2 |
| "vb_memory" | "vb.memory" | 2048 |
| "vb_linked_clone" | "vb.linked_clone" | true |
| "synced_folder" | "vm.synced_folder"| <i>see below</i> |

##### Synced folder
| "synced_folder" | path |
| --------------- |:----:|
| "host_path" | "src/" |
| "guest_path" | "/var/www/public" |

Vagrant will create the `host_path` folder if it doesn't exist. The root directory will be synced to `/vagrant` per Vagrants' defaults, giving you access to any other folders and files needed. Note that there is no '/' at the end of the `guest_path`.

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
#### Default WordPress configuration
These values will be read by the [jq utility](https://stedolan.github.io/jq/) at provisioning and passed on to WP-CLI and the `mysql` command to set up your database.

| Parameters | WP-CLI | Default | Set in Vagrant.json |
|:-----------|:------:|:-------:|---:|
| root_directory | *not used* | public | optional |
| core_directory | --path | **.** | optional |
| mysql_database | --dbname | wp_dummy | required |
| mysql_user | --dbuser | wp | required |
| mysql_password | --dbpass | wp | required |
| mysql_prefix | --dbprefix | wp_ | required |

#### Optional parameters
The `root_directory` and `core_directory` parameters are completely optional. These are mostly used in an advanced setup where WP Core is installed in its own directory. See this [Codex page](https://wordpress.org/support/article/giving-wordpress-its-own-directory/) for more info. 

### LAMP default directory structure
See above to modify where/how your site is served.

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

### Resources (directory)
Contains configuration files used during provisioning for Apache and PHP:  
`.htaccess` - `wp-scratch-box.conf` - `custom-php.ini`.
  
Please review these files and make adjustments accordingly if you change any default configuration values.

~~The `resources` folder also has a Mailcatcher installation script.~~ *Mailcatcher is deprecated. The script is still present but unlikely to work. It will be removed in the future for sure.*

### Database (directory)
A place to store your database(s). See README file in directory.

### Scripts (directory)
A place to story your custom scripts. See README file in directory.

### Vagrant plugins
If you have `vagrant-cachier` installed, the config in the Vagrantfile is set to cache by machine.
If you have `vagrant-vbguest` installed, guest additions updates is set to `false`. Manually update guest additions if really needed.

## ⚠️ Configuration Warning
If you should change the `root_directory` and `core_directory` parameters in `Vagrant.json`:
- Make sure `guest_path` is set accordingly in the `vagrant` configuration part of `Vagrant.json`.
- You will need to change paths in the apache configuration `wp-scratch-box.conf`, file is in the `resources` folder.
- Do not put a '/' at the front or end of these values.

## ⚒️ Advanced Configuration
### Vagrant Multi-Machine
By leveraging Vagrant's Multi-Machine feature, you can hook up an additional virtual machine or re-packaged boxes from VVV, Primary Vagrant, etc. alongside the main `Project` VM.

#### Muti-Machine configuration
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

### ⚠️ Multi-Machine Warning 
- All keys are required and Parent Object must be set to `"Custom"` in `Vagrant.json`.
- The default `Project`machine will **not** start and be provisioned. You can force it to start with the command `vagrant up NAME`.
- If you run both `Project` and `Custom`, setting their IP's in the same range will create a network and facilitate communication between the two machines.
- Synced folders for the `Custom` machine needs to be manually set in the `Vagrantfile` if required.

***Please refer to the [Vagrant docs](https://docs.vagrantup.com/v2/multi-machine/index.html) for more info on Multi-Machine setups.***

## 🎉 Contribute to `wp-scratch-box`
- Open to any sort of contributions.
- Suggestions and improvements can be discussed in the issue tracker/through PR.

## ⚖️ License
Released under the MIT license.  
*2015 - 2019 a pleasant view | Cristovao Verstraeten*  
<br>

***Have a pleasant view!***
