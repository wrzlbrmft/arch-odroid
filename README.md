# arch-odroid
A simple script installing [Arch Linux](https://www.archlinux.org/) on an SD
card for the
[ODROID](http://www.hardkernel.com/main/products/prdt_info.php).

The script supports the following hardware models of the
ODROID:

* ODROID-XU3/XU4 (ARMv7)
* ODROID-C2 (ARMv8)

The installation procedure pretty much matches the Installation Guides from
[Arch Linux ARM](http://archlinuxarm.org/),
but also adds some configuration settings like networking, including a static IP
address for a fully headless setup without a screen or keyboard.

After the installation you can directly login to your
ODROID
using the pre-configured IP address.

**NOTE:** Setting up wireless networking requires at least connecting a keyboard
to your
ODROID
-- but just once! ;-)

## Requirements

In order to use
`arch-odroid`,
you need an extra Linux environment (Mac support not quite there...) which is
connected to the Internet and has an SD card slot.

For the Linux environment, you can also use a Live-CD like
[Xubuntu](http://xubuntu.org/). Just make sure the following commands are
available:

* `lsblk`
* `dd`
* `parted`
* `curl`
* `tar`

## Usage Guide

In a Terminal download and unpack the latest version of
`arch-odroid`:

```
curl -L https://github.com/wrzlbrmft/arch-odroid/archive/master.tar.gz | tar zxvf -
```

Insert the SD card on which you want to install Arch Linux, but make sure none
of its partitions is mounted, otherwise unmount them. Then use `lsblk` to
determine the device name of the SD card, e.g. `/dev/mmcblk0`, and open the
configuration file:

```
vi arch-odroid-master/arch-odroid.conf
```

Make sure the `INSTALL_DEVICE` setting matches the device name of your SD card.

You may also want to change the following settings:

* `HOSTNAME`
* `TIMEZONE`
* `CONSOLE_KEYMAP`
* `SET_ETHERNET` -- if set to `YES`, then also check the other `ETHERNET_*` settings
* `SET_WIRELESS` -- if set to `YES`, then also check the other `WIRELESS_*` settings

Once you are done, save and close the configuration file.

To write and format partitions on the SD card,
`arch-odroid`
needs super-user privileges. So `su` to `root` or use `sudo` to start the
installation process:

```
sudo arch-odroid-master/arch-odroid.sh
```

**CAUTION:** The installation will delete *all* existing data on the SD card.

The installation is done, once you see

```
[arch-odroid] Wake up, Neo... The installation is done!
```

Then insert the SD card into your
ODROID
and start it up.

That's it!

You can login as the default user `alarm` with the password `alarm`.
The default root password is `root`.

### Wireless Networking

Unfortunately, the Arch Linux ARM distribution for ODROID does not contain all
packages required for wireless networking out of the box, namely:

* `crda`
* `dialog`
* `iw`
* `libnl`
* `wireless-regdb`
* `wpa_supplicant`

However, during the installation process
`arch-odroid`
downloads these packages to the SD card. While the configuration is already done
according to the `SET_WIRELESS` and `WIRELESS_*` settings, you just have to
install the packages to get wireless networking up and running.

After booting your
ODROID
from the SD card, login as `root` (password is `root`) and type in:

```
pacman -U --noconfirm /root/software/aaa.dist/*.tar.xz && reboot
```

**NOTE:** The packages are in `/root/software/aaa.dist` unless you changed the
`PACKAGE_SETS_PATH` setting.

The installation is configured to automatically connect to the given wireless
network. After the reboot you should be online.

### Initialize Pacman

Before you can install additional packages, you must initialize the pacman
keyring and populate the Arch Linux ARM package signing keys.

Login as `root` and type in:

```
pacman-key --init && pacman-key --populate archlinuxarm
```

That's it!

### Installing Yay or Yaourt

`arch-odroid`
can also download the packages required for installing
[Yay](https://github.com/Jguer/yay) or
[Yaourt](https://github.com/archlinuxfr/yaourt), by changing the `DOWNLOAD_YAY`
or `DOWNLOAD_YAOURT` settings. Both Yay and Yaourt in turn allow you to install
packages from the [AUR](https://aur.archlinux.org/).

**NOTE:** Yaourt is not maintained anymore.

Before you can install Yay or Yaourt, you first have to set up a build
environment, so login as `root` (password is `root`) and type in:

```
pacman -Syy --noconfirm --needed base-devel sudo
```

Next, configure `sudo`, allowing members of the group `wheel` to use it by
editing the `sudoers` file:

```
nano -w /etc/sudoers
```

Remove the leading `#` from the following line to uncomment it:

```
%wheel ALL=(ALL) ALL
```

Save the `sudoers` file by pressing `Ctrl-X`, `y`, `Enter` and then logout:

```
logout
```

Login again, but this time as the user `alarm` (password is `alarm`), and change
to the directory containing the Yaourt packages:

```
cd /home/alarm/software/aaa.dist
```

**NOTE:** The Yay and Yaourt packages are in `/home/alarm/software/aaa.dist`
unless you changed the `YAY_PATH` or `YAOURT_PATH` settings.

To install Yay:

```
tar xvf yay.tar.gz
cd yay
makepkg -i -s --noconfirm --needed

cd ..
```

To install Yaourt:

```
tar xvf package-query.tar.gz
cd package-query
makepkg -i -s --noconfirm --needed

cd ..

tar xvf yaourt.tar.gz
cd yaourt
makepkg -i -s --noconfirm --needed

cd ..
```

After Yay or Yaourt is installed, it's probably a good idea to check for
available package updates:

Using Yay:

```
yay -Syyu
```

Using Yaourt:

```
yaourt -Syyua
```

If there are, just follow the instructions on the screen.

That's it!

### Using an Alternative Configuration File

You can use an alternative configuration file by passing it to the installation
script:

```
arch-odroid-master/arch-odroid.sh -c my.conf
```

## License

This software is distributed under the terms of the
[GNU General Public License v3](https://www.gnu.org/licenses/gpl-3.0.en.html).
