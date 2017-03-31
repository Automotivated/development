##################################################
# Installation of the project structure to
# prevent common mistakes and quick rereleases
#
# Author: Ferry Kobus
#
##################################################

#!/bin/sh

TEMP_FILE=".env.tmp"
CONFIG_FILE=".config"
FILES="-f docker-compose.yml"
FIRST_RUN=false
INVALID="Invalid input received, try again.."
function choose_webserver() {
	read -p 'Should we setup apache or nginx (apache|nginx): ' webserver
	if [[ "$webserver" == "apache" || "$webserver" == "nginx" ]] ; then
		echo "WEBSERVER=${webserver}" >> $CONFIG_FILE
		FILES+=" -f docker-compose.${webserver}.yml"
	else
		echo $INVALID
		choose_webserver
	fi
}

function use_elastic() {
	read -p 'Should we setup elastic (y|n): ' elastic
	if [[ "$elastic" == "y" || "$elastic" == "yes" ]] ; then
		FILES+=" -f docker-compose.elastic.yml"
	fi
}

function rand() {
	export LC_CTYPE=C
	t=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
}

function get_database_config() {
	read -p 'MySQL root password: ' db_root
	if [ -z "$db_root" ] ; then
		rand
		db_root=$t
		echo "Generated root password: ${db_root}"
	fi
}

function add_project() {
	read -p 'Hostname: ' domainname
	if [ -z "$domainname" ] ; then
		echo $INVALID
		add_project
	fi
}

function setup_database() {
	read -p 'MySQL database user: ' db_user
	if [ -z "$db_user" ] ; then
		rand
		db_user=$t
		echo "Generated database user: ${db_user}"
	fi
	read -p 'MySQL database name: ' db_name
	if [ -z "$db_name" ] ; then
		rand
		db_name=$t
		echo "Generated database name: ${db_name}"
	fi
	read -p 'MySQL database password: ' db_pass
	if [ -z "$db_pass" ] ; then
		rand
		db_pass=$t
		echo "Generated database password: ${db_pass}"
	fi
}
##
# Check if we already runned the install
# If not, continue with the installation
##
if [ ! -f ".config" ] ; then
	FIRST_RUN=true
	choose_webserver
	use_elastic
	echo "FILES=${FILES}" >> $CONFIG_FILE
	get_database_config
	cat ".env.dist" > $TEMP_FILE
	sed -i "" "s/^DB_ROOT_PASSWORD=.*/DB_ROOT_PASSWORD=${db_root}/g" $TEMP_FILE
fi

if [ -f ".config" ] ; then
	echo "Adding a new project to the stack"
	add_project
	setup_database
	# setup_database
	if [ "$FIRST_RUN" == true ] ; then
		sed -i "" "s/^HOST=.*/HOST=${domainname}/g" $TEMP_FILE
		sed -i "" "s/^DB_NAME=.*/DB_NAME=${db_name}/g" $TEMP_FILE
		sed -i "" "s/^DB_USERNAME=.*/DB_USERNAME=${db_user}/g" $TEMP_FILE
		sed -i "" "s/^DB_PASSWORD=.*/DB_PASSWORD=${db_pass}/g" $TEMP_FILE
		mv $TEMP_FILE ".env"
	fi
fi
