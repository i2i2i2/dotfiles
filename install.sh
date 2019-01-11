#!/bin/sh
set -e

#   * experimental
DEFAULT_CHANNEL_VALUE="edge"
if [ -z "$CHANNEL" ]; then
	CHANNEL=$DEFAULT_CHANNEL_VALUE
fi

DEFAULT_DOWNLOAD_URL="https://download.docker.com"
if [ -z "$DOWNLOAD_URL" ]; then
	DOWNLOAD_URL=$DEFAULT_DOWNLOAD_URL
fi

DEFAULT_REPO_FILE="docker-ce.repo"
if [ -z "$REPO_FILE" ]; then
	REPO_FILE="$DEFAULT_REPO_FILE"
fi

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

	# Run setup for each distro accordingly
	case "$lsb_dist" in
		ubuntu|debian|raspbian)
			pkgs="coreutils wget curl tmux vim mosh fish git psmisc tree g++ golang python python3 default-jdk nodejs iproute2 netcat tcpdump net-tools traceroute iptables iputils-ping"
			(
				set -x
				$sh_c 'apt-get update -qq >/dev/null'
				$sh_c "apt-get install -y -qq $pkgs >/dev/null"
			)
			;;
		*)
			if [ "$lsb_dist" = "fedora" ]; then
				pkg_manager="dnf"
			else
				pkg_manager="yum"
			fi
			pkgs="coreutils wget curl tmux vim mosh fish git psmisc tree gcc golang python3 java-openjdk nodejs iproute nmap-ncat tcpdump net-tools traceroute iptables iputils"
			(
				set -x
				$sh_c "$pkg_manager install -y -q $pkgs"
			)
			;;
	esac
}

do_install_dotfiles() {

}

# wrapped up in a function so that we have some protection against only getting
# half the file during "curl | sh"
do_install
