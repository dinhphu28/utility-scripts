#!/bin/zsh
read -p 'Enter the CAPAM port number: ' capam_port
read -p 'Enter your username: ' username

income_host="0.0.0.0"
# NOTE: This is sample, you can change it to your own configuration
income_port_db_qa_dev="3306"
income_port_db_staging="3306"
income_port_http_proxy="80"

destination_db_qa_dev="10.8.0.10:3306"
destination_db_staging="10.8.0.11:3308"
destination_http_proxy="proxy.example.com:80"

function read_user_option() {
	local message=$1
	local default_option=$2
	local option
	while true; do
		read -p "$message [$(tput bold)Y$(tput sgr0)/N]($default_option) " option
		if [ -z "$option" ]; then
			option=$default_option
		fi
		case $option in
		[Yy]*)
			option="Y"
			break
			;;
		[Nn]*)
			option="N"
			break
			;;
		*)
			echo "Please answer yes (Y) or no (N)."
			;;
		esac
	done
	echo $option
}

function print_connection() {
	local option=$1
	local income_port=$2
	local destination=$3
	local option_name=${4-''}
	if [ -n "$option_name" ]; then
		option_name="$option_name "
	fi
	if [ -n "$option" ]; then
		printf "\r  [\033[00;34mConnection\033[0m] $option_name$destination running on port: \033[00;32m$income_port\033[0m\n"
	fi
}

use_qa_dev_db=$(read_user_option "Do you want to use QA/Dev Database?" "Y")
use_staging_db=$(read_user_option "Do you want to use Staging Database?" "Y")
use_http_proxy=$(read_user_option "Do you want to use HTTP Proxy?" "Y")

case $use_qa_dev_db in
'Y')
	option_qa_dev_db="-L $income_host:$income_port_db_qa_dev:$destination_db_qa_dev"
	;;
'N') option_qa_dev_db="" ;;
*) echo "[Exception] - Choose value is invalid!" ;;
esac

case $use_staging_db in
[Yy]*)
	option_staging_db="-L $income_host:$income_port_db_staging:$destination_db_staging"
	;;
[Nn]*) option_staging_db="" ;;
*) echo "[Exception] - Choose value is invalid!" ;;
esac
case $use_http_proxy in
[Yy]*)
	option_http_proxy="-L $income_host:$income_port_http_proxy:$destination_http_proxy"
	;;
[Nn]*) option_http_proxy="" ;;
*) echo "[Exception] - Choose value is invalid!" ;;
esac

ssh_tunneling_command="ssh -f -N \
  $option_qa_dev_db \
  $option_staging_db \
  $option_http_proxy \
  $username@127.0.0.214 -p $capam_port"

printf "\r  [\033[00;34mSSH Tunneling ...\033[0m]"
echo "  > $ssh_tunneling_command"
eval "$ssh_tunneling_command"
if [ $? -ne 0 ]; then
	printf "\r  [\033[00;31mError\033[0m] SSH Tunneling failed\n"
	exit 1
else
	print_connection "$option_qa_dev_db" "$income_port_db_qa_dev" "$destination_db_qa_dev" "Database QA/Dev"
	print_connection "$option_staging_db" "$income_port_db_staging" "$destination_db_staging" "Database Staging"
	print_connection "$option_http_proxy" "$income_port_http_proxy" "$destination_http_proxy" # "HTTP Proxy"
fi
