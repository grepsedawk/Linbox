#!/bin/bash -
#title          :linbox
#description    :It's winbox for linux!
#author         :Alex Piechowski
#date           :20151223
#version        :0.1
#usage          :./install.sh
#notes          :
#============================================================================
trap CleanUp INT

function CleanUp
{
	stty sane
	stopSpinner
	exit $1
}

BOOTUP=color
RES_COL=71
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
SETCOLOR_SUCCESS="echo -en \\033[0;32m"
SETCOLOR_FAILURE="echo -en \\033[0;31m"
SETCOLOR_WARNING="echo -en \\033[0;33m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"

#####
#
#  Usage: action "Thing you want to say" funcName
#
#####
#usage "action "Thing you want to say" funcName
action() {
	STRING=$1
	echo -n "$STRING "
	shift
	startSpinner
	eval "$*" 2>> linboxInstall.log && echo_success || echo_failure
	stopSpinner
	rc=$?
	echo
	return $rc
}

echo_success() {
  [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
  echo -n "[  "
  [ "$BOOTUP" = "color" ] && $SETCOLOR_SUCCESS
  echo -n $"OK"
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
  echo -n "   ]"
  echo -ne "\r"
  return 0
}

echo_failure() {
  [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
  echo -n "[ "
  [ "$BOOTUP" = "color" ] && $SETCOLOR_FAILURE
  echo -n $"ERROR"
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
  echo -n " ]"
  echo -ne "\r"
  return 1
}

function _spinner() {
    case $1 in
        start)

            # start spinner
            i=1
            sp='\|/-'
            delay=0.15

            while :
            do
                [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
                printf "[   ${sp:i++%${#sp}:1}   ]"
                sleep $delay
            done
            ;;
        stop)
            if [[ -z ${2} ]]; then
                exit 0
            fi
            kill $2 > /dev/null 2>&1
            ;;
        *)
            echo "invalid argument, try {start/stop}"
            exit 1
            ;;
    esac
}

function startSpinner {
    _spinner "start" "${1}" &
    _sp_pid=$!
    disown
}

function stopSpinner {
    _spinner "stop" $_sp_pid
    unset _sp_pid
}

#####
#
#  Functions
#
#####
function checkIfRoot() {
    if [ `whoami` != 'root' ]; then
        echo_failure
	echo
	echo
        echo "Linbox must be installed as the root user, please run the command as:"
        echo "sudo $0 or change to the root user"
        echo "Exiting install now."
        echo
        CleanUp 1
    fi
}

function enableMultiarch() {
    if $(getconf LONG_BIT) == 64; then
        dpkg --add-architecture i386 &>> linboxInstall.log
    fi
}

function aptgetUpdate() {
   apt-get update -y &>> linboxInstall.log
}

function installWine() {
    echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
    apt-get install -y wine &>> linboxInstall.log
}

function downloadWinbox() {
    mkdir /opt/winbox &>> linboxInstall.log
    cp -f bin/winbox.exe /opt/winbox/winbox.exe &>> linboxInstall.log
}

function installLinbox() {
    cp bin/linbox /usr/local/bin/linbox
}



#####
#
#  Actions
#
#####
action "Checking if root" checkIfRoot
action "Enabling multiarch if 64 bit" enableMultiarch
action "Running apt-get update" aptgetUpdate
action "Installing wine" installWine
action "Downloading Winbox" downloadWinbox
action "Installing Linbox" installLinbox
