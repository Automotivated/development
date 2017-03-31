##################################################
# Run development environment automatically
# Offcourse you can be stubborn and do everything
# by hand.
# There are some mac fixes*
#
# Author: Ferry Kobus
#
##################################################

#!/bin/sh

PROJECT="devenv"
IP="127.0.0.1"
TEMP_FILE=hosts.tmp
HOSTS_FILE=/etc/hosts
FORCE=false
KERNEL=`uname`

while [[ $# -gt 0 ]] ; do
	key="$1"
	case $key in
		-p|--project)
			PROJECT="$2"
			shift
		;;
		up)
			METHOD="up"
		;;
		down)
			METHOD="down"
		;;
		-h|--help)
			HELP=true
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

# Extract host from .env
HOST=`cat .env | grep HOST=`
HOST=${HOST:5}

##
# show help nicely formatted
##
function show_help() {
	cat <<EOF
Usage: $0 [options]
The options are space seperated, so use them
like this -p <project> -v up

-h| --help           Will print this message

-p|--project         Custom project namespace
-v|--verbose         Will output everything
-f|--force-recreate  Force recreation
EOF
}

##
# Bring the service up
##
if [ "$METHOD" == "up" ] ; then
	echo "Firing up [${HOST}] under [${PROJECT}]"
	FILES=`grep -F "FILES=" .config`

	up="docker-compose -p $PROJECT up -d ${FILES:6}"
	if [ "$FORCE" == true ] ; then
		up+=" --force-recreate"
	fi
	if [ "$VERBOSE" == true ] ; then
		eval $up
	else
		eval $up >/dev/null 2>&1
	fi

	# for all running docker containers
	for service in `docker ps -q`; do
		# Extract the servicename
		servicename=`docker inspect --format '{{ .Name }}' $service `
		validservice="${PROJECT}_apache_"
		if [[ ${servicename:1} == ${validservice}* ]] ; then
			ip=`docker inspect --format {{.NetworkSettings.Networks.${PROJECT}_server.IPAddress}} $service`
		fi
	done

	## Update hosts file
	if [ -f ${HOSTS_FILE} ]; then
		grep -v $HOST $HOSTS_FILE > $TEMP_FILE
		echo $ip '\t' $HOST '\t # Added by devenv' >> $TEMP_FILE
		sudo mv $TEMP_FILE $HOSTS_FILE
	fi

	## Fix docker ip on mac
	if [[ ${KERNEL} == *Darwin* ]] ; then
		sudo ifconfig lo0 alias $ip
	fi

##
# Bring the service down
##
elif [ "$METHOD" == "down" ] ; then
	echo "Stopping up [${HOST}] under [${PROJECT}]"
	down="docker-compose -p $PROJECT down"
	if [ "$VERBOSE" == true ] ; then
		eval $down
	else
		eval $down >/dev/null 2>&1
	fi

	if [ -f ${HOSTS_FILE} ]; then
		grep -v $HOST $HOSTS_FILE > $TEMP_FILE
		sudo mv $TEMP_FILE $HOSTS_FILE
	fi

	## Fix docker ip on mac
	if [[ ${KERNEL} == *Darwin* ]] ; then
		sudo ifconfig lo0 -alias $ip
	fi
else
	show_help
fi
