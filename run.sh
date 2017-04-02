############################################################
# Run development environment automatically
#
# Offcourse you can be stubborn and do everything by hand.
# There are some mac fixes*
#
# Maintainer: Ferry Kobus <ferry@automotivated.nl>
#
############################################################
#!/bin/sh

IP="127.0.0.1"
TEMP_FILE=".hosts.tmp"
HOSTS_FILE=/etc/hosts
FORCE=false
KERNEL=`uname`
TEMP_ENV_FILE=".env.tmp"
CONFIG_FILE=".config"
FILES="-f docker-compose.yml"
FIRST_RUN=false
INVALID="Invalid input received, try again.."
BUILD=false

while [[ $# -gt 0 ]] ; do
	key="$1"
	case $key in
		up)
			COMMAND="up"
		;;
		down)
			COMMAND="down"
		;;
		install)
			COMMAND="install"
		;;
		ssh)
			COMMAND="ssh"
		;;
		add)
			COMMAND="add"
		;;
		-h|--help)
			HELP=true
		;;
		-b|--build)
			BUILD=true
		;;
		-f|--force-recreate)
			FORCE=true
		;;
		-v|--verbose)
			VERBOSE=true
		;;
		*)
		# unknown option
		;;
	esac
	shift # past argument or value
done


# Get the current direcotry name (for example development)
function get_directory() {
	current_directory=`pwd`
	directories=(${current_directory//// })
	current_directory=${directories[${#directories[@]} - 1]}
}

##
# show help nicely formatted
##
function show_help() {
	cat <<EOF
Welcome to the Automotivated development environment

Usage: $0 COMMAND

Options:
    -h,   --help              Will print this message
    -v,   --verbose           Will output everything
    -f,   --force-recreate    Force recreation
    -b,   --build             Force rebuild of dockers

Commands:
    install                   Start a fresh installation
    add                       Add a new domain / project
    up                        Will bring the services up
    down                      Shutsdown all services
    ssh                       Directly login to the php container
    mysql                     Directly login to the mysql container
EOF
}

##
# Select the webserver when installing and
##
function choose_webserver() {
	read -p 'Should we setup apache or nginx (apache|nginx): ' WEBSERVER
	if [[ "$WEBSERVER" == "apache" || "$WEBSERVER" == "nginx" ]] ; then
		echo "WEBSERVER=${WEBSERVER}" >> $CONFIG_FILE
		FILES+=" -f docker-compose.${WEBSERVER}.yml"
	else
		echo $INVALID
		choose_webserver
	fi
}

function choose_project_name() {
	read -p 'What name would you like for your environment?: ' environment
	if [ -z "$environment" ] ; then
		PROJECT="devenv"
	else
		PROJECT=${environment}
	fi
	echo "PROJECT=${PROJECT}" >> $CONFIG_FILE
}

function use_elastic() {
	read -p 'Should we setup elastic (y|n): ' elastic
	if [[ "$elastic" == "y" || "$elastic" == "yes" ]] ; then
		FILES+=" -f docker-compose.elastic.yml"
	fi
}

function setup_hostname() {
	read -p 'Hostname: ' DOMAINNAME
	if [ -z "$DOMAINNAME" ] ; then
		echo $INVALID
		setup_hostname
	fi
}

function rand() {
	export LC_CTYPE=C
	t=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
}

function salt() {
	export LC_CTYPE=C
	s=`cat /dev/urandom | tr -dc 'a-zA-Z0-9-_{}!@#%^*()[]|.,\?:;~' | fold -w 64 | head -n 1`
}

function get_database_config() {
	read -p 'MySQL root password: ' DB_ROOT
	if [ -z "$DB_ROOT" ] ; then
		rand
		DB_ROOT=$t
		echo "Generated root password: ${DB_ROOT}"
	fi
}

function set_webserver() {
	if [[ -z "$WEBSERVER" ]] ; then
		WEBSERVER=`cat .config | grep WEBSERVER=`
		WEBSERVER=${WEBSERVER:10}
	fi
}

function set_project() {
	if [[ -z "$PROJECT" ]] ; then
		PROJECT=`cat .config | grep PROJECT=`
		PROJECT=${PROJECT:8}
	fi
}

function setup_database() {
	get_directory

	read -p 'MySQL database user: ' DB_USER
	if [ -z "$DB_USER" ] ; then
		rand
		DB_USER="${current_directory}_user_${t:0:5}"
		echo "Generated database user: ${DB_USER}"
	fi
	read -p 'MySQL database name: ' DB_NAME
	if [ -z "$DB_NAME" ] ; then
		rand
		DB_NAME="${current_directory}_name_${t:0:5}"
		echo "Generated database name: ${DB_NAME}"
	fi
	read -p 'MySQL database password: ' DB_PASS
	if [ -z "$DB_PASS" ] ; then
		rand
		DB_PASS=$t
		echo "Generated database password: ${DB_PASS}"
	fi
}

# Get the ip of the webserver for aliasing
function get_ip() {
	# Loop over all running docker containers and find our chosen webserver
	for service in `docker ps -q`; do
		# Extract the servicename
		servicename=`docker inspect --format '{{ .Name }}' $service`
		validservice="${PROJECT}_${WEBSERVER}_"
		if [[ ${servicename:1} == ${validservice}* ]] ; then
			IP=`docker inspect --format {{.NetworkSettings.Networks.${PROJECT}_server.IPAddress}} $service`
			break
		fi
	done
}

##
# Todo, multidomain / project support
##
function update_hosts_file() {
	if [ -f ${HOSTS_FILE} ]; then
		get_ip

		## Update hosts file
		grep -v $IP $HOSTS_FILE > $TEMP_FILE

		if [ "$1" == "add" ] ; then
			for entry in projects/* ; do
				HOST=${entry:9}
				echo $IP '\t' $HOST '\t # Added by [' $PROJECT '] automatically' >> $TEMP_FILE
			done
		fi

		sudo mv $TEMP_FILE $HOSTS_FILE

		## Fix docker ip on mac
		if [[ ${KERNEL} == *Darwin* ]] ; then
			if [ "$1" == "add" ] ; then
				sudo ifconfig lo0 alias ${IP}
			elif [ "$1" == "remove" ] ; then
				sudo ifconfig lo0 -alias ${IP}
			fi
		fi
	fi
}

##
# Installs a new environment from scratch
# Check if we already runned the install
# If not, continue with the installation
##
function do_install() {
	FIRST_RUN=true
	choose_project_name
	choose_webserver
	use_elastic
	echo "FILES=${FILES}" >> $CONFIG_FILE
	get_database_config
	cat ".env.dist" > $TEMP_ENV_FILE
	sed -i "" "s/^DB_ROOT_PASSWORD=.*/DB_ROOT_PASSWORD=${DB_ROOT}/g" $TEMP_ENV_FILE
	add_project
}

##
# Setup the project root and add vhosts
##
function setup_recipe() {
	echo "Which type of project do you want to add?"
	RECIPES=()
	for entry in "recipes"/* ; do
		RECIPES+=(${entry:8})
	done

	select RECIPE in "${RECIPES[@]}" ; do
		if [[ "${RECIPES[@]}" =~ "${RECIPE}" ]]; then
			break
		else
			echo $INVALID
		fi
	done

	## copy web contents for flying start
	cp -R recipes/${RECIPE}/web/ projects/${DOMAINNAME}

	## remove .gitkeep if it exists
	if [ -f "projects/${DOMAINNAME}/.gitkeep" ] ; then
		rm projects/${DOMAINNAME}/.gitkeep
	fi

	## set te new vhost
	if [ "$WEBSERVER" == "apache" ] ; then
		VHOST="services/apache/vhosts/${DOMAINNAME}.conf"
	elif [ "$WEBSERVER" == "nginx" ] ; then
		VHOST="services/nginx/config/conf.d/${DOMAINNAME}.conf"
	fi

	## rewrite contents
	cat recipes/${RECIPE}/config/${WEBSERVER}.${RECIPE}.conf > $VHOST
	sed -i "" "s/domain.tld/${DOMAINNAME}/g" $VHOST
	sed -i "" "s#/projects/project#/projects/${DOMAINNAME}#g" $VHOST

	## Add the database to our database..hm.. something like that
	add_database

	## Execute recipe specific operations
	if [ "$RECIPE" == "wordpress" ] ; then
		setup_wordpress
	elif [ "$RECIPE" == "symfony" ] ; then
		echo "NOT IMPLEMENTED YET"
		exit
	else
		echo "NOT IMPLEMENTED YET"
		exit
	fi
}

function setup_wordpress() {
	## Install via composer within the docker
	docker exec -i ${PROJECT}_php_1 /bin/bash <<EOF
		cd /var/www/projects/$DOMAINNAME
		composer create-project roots/bedrock .
		exit
EOF
	WP_ENV="projects/$DOMAINNAME/.env"
	cat projects/$DOMAINNAME/.env.example > $WP_ENV
	sed -i "" "s/^DB_NAME=.*/DB_NAME=${DB_NAME}/g" $WP_ENV
	sed -i "" "s/^DB_USER=.*/DB_USER=${DB_USER}/g" $WP_ENV
	sed -i "" "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/g" $WP_ENV
	sed -i "" "s/^# DB_HOST=.*/DB_HOST=mysql/g" $WP_ENV
	sed -i "" "s#^WP_HOME=.*#WP_HOME=http://$DOMAINNAME#g" $WP_ENV
	salt
	sed -i "" "s/^AUTH_KEY=.*/AUTH_KEY='${s}'/g" $WP_ENV
	salt
	sed -i "" "s/^SECURE_AUTH_KEY=.*/SECURE_AUTH_KEY='${s}'/g" $WP_ENV
	salt
	sed -i "" "s/^LOGGED_IN_KEY=.*/LOGGED_IN_KEY='${s}'/g" $WP_ENV
	salt
	sed -i "" "s/^NONCE_KEY=.*/NONCE_KEY='${s}'/g" $WP_ENV
	salt
	sed -i "" "s/^AUTH_SALT=.*/AUTH_SALT='${s}'/g" $WP_ENV
	salt
	sed -i "" "s/^SECURE_AUTH_SALT=.*/SECURE_AUTH_SALT='${s}'/g" $WP_ENV
	salt
	sed -i "" "s/^LOGGED_IN_SALT=.*/LOGGED_IN_SALT='${s}'/g" $WP_ENV
	salt
	sed -i "" "s/^NONCE_SALT=.*/NONCE_SALT='${s}'/g" $WP_ENV
}

function add_database() {
	if [ "$FIRST_RUN" == false ] ; then
		## Add the database!
		PASS=`cat .env | grep DB_ROOT_PASSWORD=`
		PASS=${PASS:17}
		docker exec -i ${PROJECT}_mysql_1 /bin/bash <<EOF
			mysql --user=root --password=$PASS
			create database $DB_NAME;
			create user $DB_USER;
			grant all on $DB_NAME.* to '$DB_USER'@'%' identified by '$DB_PASS';
			flush privileges;
			quit
			exit
EOF
	fi
}

##
# Add a project
##
function add_project() {
	echo "Adding a new project to the stack"
	setup_hostname
	# Setup the database
	setup_database
	if [ "$FIRST_RUN" == true ] ; then
		sed -i "" "s/^DB_NAME=.*/DB_NAME=${DB_NAME}/g" $TEMP_ENV_FILE
		sed -i "" "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USER}/g" $TEMP_ENV_FILE
		sed -i "" "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/g" $TEMP_ENV_FILE
		mv $TEMP_ENV_FILE ".env"
	fi
	get_it_up

	setup_recipe

	FORCE=true
	get_it_up
}


##
# Bring the service up
##
function get_it_up() {
	echo "Firing up [${PROJECT}]"
	FILES=`grep -F "FILES=" .config`

	up="docker-compose -p $PROJECT ${FILES:6} up -d"
	if [ "$FORCE" == true ] ; then
		up+=" --force-recreate"
	fi
	if [ "$BUILD" == true ] ; then
		up+=" --build"
	fi

	if [ "$VERBOSE" == true ] ; then
		eval $up
	else
		eval $up >/dev/null 2>&1
	fi
	update_hosts_file add
}

##
# Bring the service down
##
function get_it_down() {
	echo "Stopping [${PROJECT}]"
	# first remove ip from the list before shutting down
	update_hosts_file remove

	down="docker-compose -p $PROJECT down --remove-orphans"
	if [ "$VERBOSE" == true ] ; then
		eval $down
	else
		eval $down >/dev/null 2>&1
	fi
}

##
# Get into a specific service
##
function get_it_in() {
	# Loop over all running docker containers and find our chosen webserver
	for service in `docker ps -q`; do
		# Extract the servicename
		servicename=`docker inspect --format '{{ .Name }}' $service`
		validservice="${PROJECT}_php_"
		if [[ ${servicename:1} == ${validservice}* ]] ; then
			CONTAINER=$service
			break
		fi
	done
	if [ ! -z "$CONTAINER" ] ; then
		docker exec -it $CONTAINER /bin/bash
	fi
}

## Always check the config!
function check_config() {
	# check if .config exists
	if [ ! -f ".config" ] ; then
		echo ".config file not found, please run installlation first"
		exit
	fi
	set_webserver
	set_project
}

##
# What should we execute?
##
if [ "$COMMAND" == "up" ] ; then
	check_config
	get_it_up
elif [ "$COMMAND" == "down" ] ; then
	check_config
	get_it_down
elif [ "$COMMAND" == "add" ] ; then
	check_config
	add_project
elif [ "$COMMAND" == "ssh" ] ; then
	check_config
	get_it_in
elif [ "$COMMAND" == "mysql" ] ; then
	check_config
	echo "Not implemented yet"
	exit
elif [ "$COMMAND" == "install" ] ; then
	# check if .config exists
	if [ -f ".config" ] ; then
		echo ".config file found, aborting installation"
		exit
	fi
	do_install
	echo "Successfully installed!"
else
	show_help
fi
