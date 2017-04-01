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
TEMP_FILE="hosts.tmp"
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
EOF
}

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

function choose_project() {
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

function set_webserver() {
	if [[ -z "$webserver" ]] ; then
		webserver=`cat .config | grep WEBSERVER=`
		webserver=${webserver:10}
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
	read -p 'MySQL database user: ' db_user
	if [ -z "$db_user" ] ; then
		rand
		db_user="${current_directory}_user_${t:0:5}"
		echo "Generated database user: ${db_user}"
	fi
	read -p 'MySQL database name: ' db_name
	if [ -z "$db_name" ] ; then
		rand
		db_name="${current_directory}_name_${t:0:5}"
		echo "Generated database name: ${db_name}"
	fi
	read -p 'MySQL database password: ' db_pass
	if [ -z "$db_pass" ] ; then
		rand
		db_pass=$t
		echo "Generated database password: ${db_pass}"
	fi
}

function get_ip() {
	# Loop over all running docker containers and find our chosen webserver
	for service in `docker ps -q`; do
		# Extract the servicename
		servicename=`docker inspect --format '{{ .Name }}' $service`
		validservice="${PROJECT}_${webserver}_"
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
		for entry in "projects"/* ; do
			HOST=${entry:9}
			if [ "$1" == "add" ] ; then
				echo $IP '\t' $HOST '\t # Added by [' $PROJECT '] automatically' >> $TEMP_FILE
			elif [ "$1" == "remove" ] ; then
				grep -v $HOST $HOSTS_FILE > $TEMP_FILE
			fi
		done
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

function setup_hostname() {
	read -p 'Hostname: ' domainname
	if [ -z "$domainname" ] ; then
		echo $INVALID
		setup_hostname
	fi
}

##
# Installs a new environment from scratch
# Check if we already runned the install
# If not, continue with the installation
##
function do_install() {
	FIRST_RUN=true
	choose_project
	choose_webserver
	use_elastic
	echo "FILES=${FILES}" >> $CONFIG_FILE
	get_database_config
	cat ".env.dist" > $TEMP_ENV_FILE
	sed -i "" "s/^DB_ROOT_PASSWORD=.*/DB_ROOT_PASSWORD=${db_root}/g" $TEMP_ENV_FILE
	add_project
}

function setup_apache_project() {
	VHOST="services/apache/vhosts/${domainname}.conf"
	cat services/apache/vhosts/example.config > $VHOST
	create_project
}

function setup_nginx_project() {
	VHOST="services/nginx/config/conf.d/${domainname}.conf"
	cat services/nginx/config/conf.d/example.config > $VHOST
	create_project
}

function create_project() {
	sed -i "" "s/domain.tld/${domainname}/g" $VHOST
	sed -i "" "s#/projects/project#/projects/${domainname}#g" $VHOST
	cp -R templates/default projects/${domainname}
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
		sed -i "" "s/^DB_NAME=.*/DB_NAME=${db_name}/g" $TEMP_ENV_FILE
		sed -i "" "s/^DB_USERNAME=.*/DB_USERNAME=${db_user}/g" $TEMP_ENV_FILE
		sed -i "" "s/^DB_PASSWORD=.*/DB_PASSWORD=${db_pass}/g" $TEMP_ENV_FILE
		mv $TEMP_ENV_FILE ".env"
	fi

	if [ "$webserver" == "apache" ] ; then
		setup_apache_project
	fi

	if [ "$webserver" == "nginx" ] ; then
		setup_nginx_project
	fi
}

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
		docker exec -it $CONTAINER /bin/sh
	fi
}

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


##
# http://stackoverflow.com/questions/36627980/how-to-execute-commands-in-docker-container-as-part-of-bash-shell-script
##

# docker exec -i CONTAINER_NAME /bin/sh <<'EOF'
# cd /var/www/projects/$domainname
# rm -rf *
# composer create-project roots/bedrock .
# exit
# EOF
