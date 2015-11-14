# arch-xu4
A simple script installing [Arch Linux](https://www.archlinux.org/) on an SD
card for the
[ODROID-XU4](http://www.hardkernel.com/main/products/prdt_info.php).

The installation procedure pretty much matches the
[Arch Linux ARM Installation Guide](http://archlinuxarm.org/platforms/armv7/samsung/odroid-xu4),
but also adds some configuration settings like networking, including a static IP
address for a fully screen-less setup.

## Requirements

In order to use
`arch-xu4`,
you need a Linux environment (Mac support is on its way...) which is online and
an SD card slot.

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
`arch-xu4`:

```
curl -L https://github.com/wrzlbrmft/arch-xu4/archive/master.tar.gz | tar zxvf -
```

Insert the SD card on which you want to install Arch Linux, but make sure none
of its partitions is mounted, otherwise unmount them. Then determine the device
name of the SD card, e.g. `/dev/mmcblk0`, and open the configuration file:

```
vi arch-xu4-master/arch-xu4.conf
```

Make sure the `INSTALL_DEVICE` setting matches the device name of your SD card.

You may also want to change the following settings:

* `HOSTNAME`
* `TIMEZONE`
* `NETWORK_ADDRESS`, `NETWORK_GATEWAY` and `NETWORK_DNS`

Once you are done, save and close the configuration file.

To write and format partitions on the SD card,
`arch-xu4`
needs super-user privileges. So `su` to `root` or use `sudo` to start the
installation process:

```
sudo arch-xu4-master/arch-xu4.sh
```

**CAUTION:** The installation will delete *all* existing data on the SD card.

The installation is done, once you see

```
[arch-xu4] Wake up, Neo... The installation is done!
```

Then insert the SD card into your ODROID-XU4 and start it up.

That's it!

You can login as the default user `alarm` with the password `alarm`.
The default root password is `root`.

### Using an Alternative Configuration File

You can use an alternative configuration file by passing it to the installation
script:

```
arch-xu4-master/arch-xu4.sh -c my.conf
```

## License

This software is distributed under the terms of the
[GNU General Public License v3](https://www.gnu.org/licenses/gpl-3.0.en.html).
