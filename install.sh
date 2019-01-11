#!/bin/sh
set -e

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

get_distribution() {
	lsb_dist=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	echo "$lsb_dist"
}

get_version() {
	lsb_ver=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_ver="$(. /etc/os-release && echo "$VERSION_ID")"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	echo "$lsb_ver"
}

do_install_pkg() {
	user="$(id -un 2>/dev/null || true)"

	sh_c='sh -c'
	if [ "$user" != 'root' ]; then
		if command_exists sudo; then
			sh_c='sudo -E sh -c'
		elif command_exists su; then
			sh_c='su -c'
		else
			cat >&2 <<-'EOF'
			Error: this installer needs the ability to run commands as root.
			We are unable to find either "sudo" or "su" available to make this happen.
			EOF
			exit 1
		fi
	fi

	# perform some very rudimentary platform detection
	lsb_dist=$( get_distribution )
	lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
	lsb_ver=$( get_version )

	# Run setup for each distro accordingly
	case "$lsb_dist" in
		ubuntu|debian|raspbian)
			pkgs="apt-utils coreutils wget curl tmux vim mosh fish git psmisc tree g++ golang python python3 nodejs iproute2 netcat tcpdump net-tools traceroute iptables iputils-ping"
			(
				set -x
				$sh_c 'apt-get update -qq >/dev/null'
				for pkg in $pkgs; do
					$sh_c "apt-get install -y -qq $pkg >/dev/null"
				done
			)
			;;
		fedora)
			pkgs="coreutils wget curl tmux vim mosh fish git psmisc findutils tree gcc golang python2 python3 nodejs iproute nmap-ncat tcpdump net-tools traceroute iptables iputils"
			(
				set -x
				for pkg in $pkgs; do
					$sh_c "dnf install -y -q $pkg"
				done
			)
			;;
		*) # assume rhel or centos
			url="https://dl.fedoraproject.org/pub/epel/epel-release-latest-$lsb_ver.noarch.rpm"
			pkgs="yum-utils coreutils vim-enhanced which wget curl tmux mosh fish git psmisc tree gcc golang python nodejs iproute nmap-ncat tcpdump net-tools traceroute iptables iputils"
			(
				set -x
				if ! yum list installed epel-release ; then
					$sh_c "yum install -y -q $url"
				fi
				for pkg in $pkgs; do
					$sh_c "yum install -y -q $pkg"
				done
			)
			;;
	esac
}

do_install_dotfiles() {
	hash=$(date +%s | sha256sum | head -c 8)
	installDir="/tmp/myworkspace_$hash"
	echo $installDir
	mkdir -p $installDir
	if ! git clone "https://github.com/i2i2i2/dotfiles" $installDir; then
		exit 1
	fi

	backupOpt="--backup=simple --suffix=.mybackup"
	(
		set -x
		cd $installDir/src
		for dir in `find . -type d`; do
			install -m 755 -d $HOME/$dir;
			for file in `find $dir -maxdepth 1 -type f`; do
				install -m 644 $backupOpt $file $HOME/$dir
			done
		done;
	)
	rm -rf $installDir
	exit 0
}

do_install() {
	do_install_pkg
	do_install_dotfiles
}

# wrapped up in a function so that we have some protection against only getting
# half the file during "curl | sh"
do_install
