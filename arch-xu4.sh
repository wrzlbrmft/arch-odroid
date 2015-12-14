#!/usr/bin/env bash

INSTALL_HOME=$( cd "`dirname "${BASH_SOURCE[0]}"`" && pwd )
INSTALL_SCRIPT="`basename "${BASH_SOURCE[0]}"`"
INSTALL_NAME="`printf "$INSTALL_SCRIPT" | awk -F '.' '{ print $1 }'`"

doPrintPrompt() {
	printf "[$INSTALL_NAME] $*"
}

doPrint() {
	doPrintPrompt "$*\n"
}

doPrintHelpMessage() {
	printf "Usage: ./$INSTALL_SCRIPT [-h] [-c config]\n"
}

while getopts :hc: opt; do
	case "$opt" in
		h)
			doPrintHelpMessage
			exit 0
			;;

		c)
			INSTALL_CONFIG="$OPTARG"
			;;

		:)
			printf "ERROR: "
			case "$OPTARG" in
				c)
					printf "Missing config file"
					;;
			esac
			printf "\n"
			exit 1
			;;

		\?)
			printf "ERROR: Invalid option ('-$OPTARG')\n"
			exit 1
			;;
	esac
done
shift $((OPTIND - 1))

if [ -z "$INSTALL_CONFIG" ]; then
	INSTALL_CONFIG="$INSTALL_HOME/$INSTALL_NAME.conf"
fi

if [ ! -f "$INSTALL_CONFIG" ]; then
	printf "ERROR: Config file not found ('$INSTALL_CONFIG')\n"
	exit 1
fi

. "$INSTALL_CONFIG"

# =================================================================================
#    F U N C T I O N S
# =================================================================================

doConfirmInstall() {
	doPrint "Installing to '$INSTALL_DEVICE' - ALL DATA ON IT WILL BE LOST!"
	doPrint "Enter 'YES' (in capitals) to confirm and start the installation."

	doPrintPrompt "> "
	read i
	if [ "$i" != "YES" ]; then
		doPrint "Aborted."
		exit 0
	fi

	for i in {10..1}; do
		doPrint "Starting in $i - Press CTRL-C to abort..."
		sleep 1
	done
}

getAllPartitions() {
	lsblk -l -n -o NAME "$INSTALL_DEVICE" | grep -v "^$INSTALL_DEVICE_NAME$"
}

doFlush() {
	sync
	sync
	sync
}

doWipeAllPartitions() {
	for i in $( getAllPartitions | sort -r ); do
		umount "$INSTALL_DEVICE_HOME/$i"
		dd if=/dev/zero of="$INSTALL_DEVICE_HOME/$i" bs=1M count=1
	done

	doFlush
}

doPartProbe() {
	partprobe "$INSTALL_DEVICE"
}

doWipeDevice() {
	dd if=/dev/zero of="$INSTALL_DEVICE" bs=1M count=1

	doFlush
	doPartProbe
}

doCreateNewPartitionTable() {
	parted -s -a optimal "$INSTALL_DEVICE" mklabel "$1"
}

doCreateNewPartitions() {
	local START="1"; local END="100%"
	parted -s -a optimal "$INSTALL_DEVICE" mkpart primary "${START}MiB" "${END}MiB"

	parted -s -a optimal "$INSTALL_DEVICE" set 1 boot on

	doFlush
	doPartProbe
}

doDetectDevices() {
	local ALL_PARTITIONS=($( getAllPartitions ))

	ROOT_DEVICE="$INSTALL_DEVICE_HOME/${ALL_PARTITIONS[0]}"
}

doMkfs() {
	case "$1" in
		fat32)
			mkfs -t fat -F 32 -n "$2" "$3"
			;;

		*)
			mkfs -t "$1" -L "$2" "$3"
			;;
	esac
}

doFormat() {
	doMkfs "$ROOT_FILESYSTEM" "$ROOT_LABEL" "$ROOT_DEVICE"
}

doMount() {
	mkdir -p root
	mount "$ROOT_DEVICE" root
}

doDownloadArchLinux() {
	if [ ! -f "`basename "$ARCH_LINUX_DOWNLOAD"`" ] || [ "$ARCH_LINUX_DOWNLOAD_FORCE" == "yes" ]; then
		rm -f "`basename "$ARCH_LINUX_DOWNLOAD"`"
		curl -LO "$ARCH_LINUX_DOWNLOAD"
	fi
}

doUnpackArchLinux() {
	tar xvf "`basename "$ARCH_LINUX_DOWNLOAD"`" -C root -p

	doPrint "Flushing - this might take a while..."
	doFlush
}

doFinalizeBoot() {
	cd root/boot
	sh sd_fusing.sh "$INSTALL_DEVICE"
	cd ../..

	doFlush
}

doSetHostname() {
	cat > root/etc/hostname << __END__
$1
__END__
}

doSetTimezone() {
	ln -sf "/usr/share/zoneinfo/$1" root/etc/localtime
}

doSetNetwork() {
	cat > "root/etc/systemd/network/$NETWORK_INTERFACE.network" << __END__
[Match]
Name=$NETWORK_INTERFACE

[Network]
DNS=$NETWORK_DNS

[Address]
Address=$NETWORK_ADDRESS

[Route]
Gateway=$NETWORK_GATEWAY
__END__
}

doDisableIpv6() {
	cat > root/etc/sysctl.d/40-ipv6.conf << __END__
ipv6.disable_ipv6=1
__END__
}

doBashLogoutClear() {
	cat >> root/root/.bash_logout << __END__
clear
__END__
}

doSshAcceptKeyTypeSshDss() {
	cat >> root/etc/ssh/ssh_config << __END__
Host *
  PubkeyAcceptedKeyTypes=+ssh-dss
__END__

	cat >> root/etc/ssh/sshd_config << __END__
PubkeyAcceptedKeyTypes=+ssh-dss
__END__
}

doSymlinkHashCommands() {
	ln -s /usr/bin/md5sum root/usr/local/bin/md5
	ln -s /usr/bin/sha1sum root/usr/local/bin/sha1
}

doOptimizeSwappiness() {
	cat > root/etc/sysctl.d/99-sysctl.conf << __END__
vm.swappiness=$OPTIMIZE_SWAPPINESS_VALUE
__END__
}

doDownloadPackage() {
	local REPOSITORY="`printf "$1" | awk -F '/' '{ print $1 }'`"
	local PACKAGE="`printf "$1" | awk -F '/' '{ print $2 }'`"

	local PACKAGE_FILE="`curl -sL "$ARCH_LINUX_PACKAGES_URL$REPOSITORY" | sed -e 's/<[^>]*>//g' | grep "$PACKAGE-.*xz[^.]" | awk '{ print \$1 }'`"
	local PACKAGE_FILE_DOWNLOAD="$ARCH_LINUX_PACKAGES_URL$REPOSITORY/$PACKAGE_FILE"

	mkdir -p "root$DOWNLOAD_PACKAGE_SETS_PATH"
	curl -L "$PACKAGE_FILE_DOWNLOAD" -o "root$DOWNLOAD_PACKAGE_SETS_PATH/$PACKAGE_FILE"
}

doDownloadPackageSets() {
	for i in $DOWNLOAD_PACKAGE_SETS; do
		for j in ${PACKAGE_SET[$i]}; do
			doDownloadPackage "$j"
		done
	done
}

doUnmount() {
	umount root
	rmdir root
}

# =================================================================================
#    M A I N
# =================================================================================

doConfirmInstall

doWipeAllPartitions
doWipeDevice

doCreateNewPartitionTable "$PARTITION_TABLE_TYPE"

doCreateNewPartitions
doDetectDevices

doFormat
doMount

doDownloadArchLinux
doUnpackArchLinux

doFinalizeBoot

doSetHostname "$HOSTNAME"
doSetTimezone "$TIMEZONE"

[ "$SET_NETWORK" == "yes" ] && doSetNetwork

[ "$DISABLE_IPV6" == "yes" ] && doDisableIpv6

[ "$ROOT_USER_BASH_LOGOUT_CLEAR" == "yes" ] && doBashLogoutClear

[ "$SSH_ACCEPT_KEY_TYPE_SSH_DSS" == "yes" ] && doSshAcceptKeyTypeSshDss

[ "$SYMLINK_HASH_COMMANDS" == "yes" ] && doSymlinkHashCommands

[ "$OPTIMIZE_SWAPPINESS" == "yes" ] && doOptimizeSwappiness

doDownloadPackageSets

doUnmount

doPrint "Wake up, Neo... The installation is done!"

exit 0
