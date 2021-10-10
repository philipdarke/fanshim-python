#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ON_THRESHOLD=65
OFF_THRESHOLD=55
LOW_TEMP=30
HIGH_TEMP=85
DELAY=5
POSITIONAL_ARGS=()
BRIGHTNESS=0.1
PYTHON="python3"
PIP="pip3"
PSUTIL_MIN_VERSION="5.6.7"

ON_THRESHOLD_SET=false
OFF_THRESHOLD_SET=false

SERVICE_PATH=/etc/systemd/system/pimoroni-fanshim.service

USAGE="sudo ./install-service.sh --off-threshold <n> --on-threshold <n> --low-temp <n> --high-temp <n> --delay <n> --brightness <n> --venv <python_virtual_environment>"

# Convert Python path to absolute for systemd
PYTHON=`type -P $PYTHON`

while [[ $# -gt 0 ]]; do
	K="$1"
	case $K in
	-o|--on-threshold)
		ON_THRESHOLD="$2"
		ON_THRESHOLD_SET=true
		shift
		shift
		;;
	-f|--off-threshold)
		OFF_THRESHOLD="$2"
		OFF_THRESHOLD_SET=true
		shift
		shift
		;;
	-G|--low-temp)
		LOW_TEMP="$2"
		shift
		shift
		;;
	-R|--high-temp)
		HIGH_TEMP="$2"
		shift
		shift
		;;
	-d|--delay)
		DELAY="$2"
		shift
		shift
		;;
	-r|--brightness)
		BRIGHTNESS="$2"
		shift
		shift
		;;
	--venv)
		VENV="$(realpath ${2%/})/bin"
		PYTHON="$VENV/python3"
		PIP="$VENV/pip3"
		shift
		shift
		;;
	*)
		if [[ $1 == -* ]]; then
			printf "Unrecognised option: $1\n";
			printf "Usage: $USAGE\n";
			exit 1
		fi
		POSITIONAL_ARGS+=("$1")
		shift
	esac
done

if ! ( type -P "$PYTHON" > /dev/null ) ; then
	if [ "$PYTHON" == "python3" ]; then
		printf "fanshim controller requires Python 3\n"
		printf "You should run: 'sudo apt install python3'\n"
	else
		printf "Cannot find virtual environment.\n"
		printf "Set to base of virtual environment i.e. <venv>/bin/python3\n"
	fi
	exit 1
fi

if ! ( type -P "$PIP" > /dev/null ) ; then
	printf "fanshim controller requires Python 3 pip\n"
	if [ "$PIP" == "pip3" ]; then
		printf "You should run: 'sudo apt install python3-pip'\n"
	else
		printf "Ensure that your virtual environment has pip3 installed.\n"
	fi
	exit 1
fi

set -- "${POSITIONAL_ARGS[@]}"

EXTRA_ARGS=""

if ! [ "$1" == "" ]; then
	if [ $ON_THRESHOLD_SET ]; then
		printf "Refusing to overwrite explicitly set On Threshold ($ON_THRESHOLD) with positional argument!\n"
		printf "Please double-check your arguments and use one or the other!\n"
		exit 1
	fi
	ON_THRESHOLD=$1
fi

if ! [ "$2" == "" ]; then
	if [ $OFF_THRESHOLD_SET ]; then
		printf "Refusing to overwrite explicitly set Off Threshold ($OFF_THRESHOLD) with positional argument!\n"
		printf "Please double-check your arguments and use one or the other!\n"
		exit 1
	fi
	(( OFF_THRESHOLD = ON_THRESHOLD - $2 ))
fi

cat << EOF
Setting up pimoroni-fanshim.service:

Off threshold:    $OFF_THRESHOLD C
On threshold:     $ON_THRESHOLD C
Low temp:         $LOW_TEMP C
High temp:        $HIGH_TEMP C
Delay:            $DELAY seconds
Brightness:       $BRIGHTNESS

To change these options, run $USAGE or edit $SERVICE_PATH.

EOF

read -r -d '' UNIT_FILE << EOF
[Unit]
Description=Fan Shim Service
After=multi-user.target

[Service]
Type=simple
WorkingDirectory=$(pwd)
ExecStart=$PYTHON $(pwd)/automatic.py --on-threshold $ON_THRESHOLD --off-threshold $OFF_THRESHOLD --low-temp $LOW_TEMP --high-temp $HIGH_TEMP --delay $DELAY --brightness $BRIGHTNESS $EXTRA_ARGS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

printf "Checking for lgpio (for Pi 4 Ubuntu 20.04+ support)...\n"
$PYTHON - <<EOF
import lgpio
EOF

if [ $? -ne 0 ]; then
	printf "Installing lgpio\n"
	$PIP install lgpio
else
	printf "lgpio is installed\n"
fi

printf "Checking for fanshim...\n"
$PYTHON - > /dev/null 2>&1 <<EOF
import fanshim
EOF

if [ $? -ne 0 ]; then
	printf "Installing fanshim\n"
	$PIP install fanshim
else
	printf "fanshim is installed\n"
fi

printf "Checking for psutil >= $PSUTIL_MIN_VERSION...\n"
$PYTHON - > /dev/null 2>&1 <<EOF
import sys
import psutil
from pkg_resources import parse_version
sys.exit(not parse_version(psutil.__version__) >= parse_version('$PSUTIL_MIN_VERSION'))
EOF

if [ $? -ne 0 ]; then
	printf "Installing psutil\n"
	$PIP install --ignore-installed psutil
else
	printf "psutil >= $PSUTIL_MIN_VERSION already installed\n"
fi

printf "\nInstalling service to: $SERVICE_PATH\n"
echo "$UNIT_FILE" > $SERVICE_PATH
systemctl daemon-reload
systemctl enable --no-pager pimoroni-fanshim.service
systemctl restart --no-pager pimoroni-fanshim.service
systemctl status --no-pager pimoroni-fanshim.service
