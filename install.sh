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

# function setup_database() {

# }

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
	sed -n "s/^DB_ROOT_PASSWORD=.*/DB_ROOT_PASSWORD=${db_root}/gpw" ".env.dist" > $TEMP_FILE
	cat $TEMP_FILE
fi

if [ -f ".config" ] ; then
	echo "Adding a new project to the stack"
	add_project
	# setup_database
	if [ "$FIRST_RUN" == true ] ; then
		sed -n "s/^HOST=.*/HOST=${domainname}/gpw $TEMP_FILE" > $TEMP_FILE
		mv $TEMP_FILE ".env"
	fi
fi
