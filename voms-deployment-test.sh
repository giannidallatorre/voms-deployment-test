#!/bin/bash
trap "exit 1" TERM
export TOP_PID=$$

# Supported components
supported_components="server, clients, clients3, api-java, api-java3"

# Supported platforms
supported_platforms="SL5, SL6, Deb6"

# Supported deployment modes
supported_modes="clean, upgrade, update"

# Repo from which scripts should be fetched
script_repo="https://raw.github.com/italiangrid/voms-deployment-test/master"

boolean_values="yes,no"

ARGS=$(getopt -o c:p:m:r:u: -l "component:platform:mode:repo:upgrade:" -n "voms-deployment-test.sh" -- "$@")

if [ $? -ne 0 ]; then
    echo "No arguments specified"
  exit 1
fi

eval set -- "$ARGS"	

echo "Parsing args..."

while true;
do
	case "$1" in
		-c | --component)
		shift
		COMPONENT="$1"
		shift
		;;
		-p | --platform)
		shift
		PLATFORM="$1"
		shift
		;;
		-m | --mode)
		shift
		MODE="$1"
		shift
		;;
		-r | --repo)
		shift
		REPO="$1"
		shift
		;;
		-u | --upgrade)
		shift
		UPGRADE="$1"
		shift
		;;
		--)
		shift
		break
		;;
	esac
done


usage() {	
	echo
	echo "usage: voms-deployment-test -c <COMPONENT> -p <PLATFORM> -m <MODE> [-r REPO] [-u UPGRADE]"
	echo
	echo "COMPONENT: $supported_components"
	echo "PLATFORM: $supported_platforms"
	echo "MODE: $supported_modes"
	echo "REPO: A repo url to be used instead of the default repo"
	echo "UPGRADE: Perform database upgrade. (yes/no)"
	kill -TERM $TOP_PID
}

## Input validation ##
[[ -z $COMPONENT ]] && echo "Please provide a value for COMPONENT." && usage
[[ -z $PLATFORM ]] && echo "Please provide a value for PLATFORM." && usage 
[[ -z $MODE ]] && echo "Please provide a value for MODE." && usage

if [ -z $UPGRADE ]; then
	UPGRADE="no"
fi

if [ -n $UPGRADE ]; then
	[[ $boolean_values =~ $UPGRADE ]] || ( echo "Invalid upgrade value: $UPGRADE. Expected value: $boolean_values" && usage)
fi

if [ -n $REPO ]; then
	if [ "$REPO" = "NULL" ]; then
		REPO=""
	fi
fi



[[ $supported_components =~ $COMPONENT ]] || ( echo "Invalid component value: $COMPONENT." && usage )

[[ $supported_platforms =~ $PLATFORM ]] || ( echo "Invalid platform value: $PLATFORM." && usage )

[[ $supported_modes =~ $MODE ]] || ( echo "Invalid mode value: $MODE." && usage )

# The platform environment script
env_script=""

# The deployment script
deployment_script=""

case "$PLATFORM" in
	SL5) 
		env_script="emi3-setup-sl5.sh"
		;;
	SL6)
		env_script="emi3-setup-sl6.sh"
		;;
	Deb6)
		env_script="emi3-setup-deb.sh"
		;;
esac


if [ "$COMPONENT" = "server" ]; then
	case "$MODE" in
		clean)
			deployment_script="emi-voms-clean-deployment.sh"
			;;
		upgrade)
			deployment_script="emi-voms-upgrade-deployment.sh"
			;;
		update)
			deployment_script="emi-voms-update-deployment.sh"
			;;
	esac
fi

if [ "$COMPONENT" = "clients" ]; then
	case "$MODE" in
		clean)
			if [ "$PLATFORM" = "Deb6" ]; then
				deployment_script="voms-clients-clean-deployment-deb.sh"
			else
				deployment_script="voms-clients-clean-deployment.sh"
			fi
			;;
		upgrade)
			deployment_script="voms-clients-upgrade-deployment.sh"
			;;
		update)
			echo "Still unimplemented!"
			kill -TERM $TOP_PID
			;;
	esac
fi

echo "### VOMS Deployment Test ###"

echo "Host: `hostname -f`"
echo "Date: `date`"
echo "Environment script: $script_repo/$env_script"	
echo "Deployment script: $script_repo/$deployment_script"

echo "Fetching environment script from GITHUB..."
echo
wget --no-check-certificate $script_repo/$env_script -O $env_script

echo "Fetching deployment script from GITHUB..."
echo
wget --no-check-certificate $script_repo/$deployment_script -O $deployment_script

source $env_script
chmod +x ${deployment_script}

if [ -n "$REPO" ]; then
	echo "Setting custom repo to: $REPO"
	export DEFAULT_VOMS_REPO=$REPO
fi

if [ "$UPGRADE" = "yes" ]; then
	echo "Requiring database upgrade."
	export PERFORM_DATABASE_UPGRADE="yes"
fi

echo "### <Environment> ### "
env
echo "### </Environment> ###"

echo "Starting deployment test"
echo
./$deployment_script