#!/bin/bash

#
#	OSC BASH SCRIPT ASSIGNMENT 2022 S1
#	TASK TWO
#
#	AARDHYN LAVENDER
#

# Logs details of the current script execution to a file
function Log() {
    if [ ! -d ./logs ];
    then
        mkdir ./logs
        Log "UPDATE" "No log directory was present -> Creating" # recursive function...
    fi

    local out="logs/$timestamp.log"
    printf "[ $1 ]\t$2\n" >> $out

    if [ -n "$3" ];
    then
        printf "  TRACE:\t$3\n" >> $out
    fi

    if [ -n "$4" ];
    then
        printf "  EXPECT:\t$4\n" >> $out
    fi
    echo >> $out

    # create a copy of the latest log
    cat $out > logs/latest.log
}

# repeats a given character n times
function Repeat() {
    Log "UPDATE" "Repeating character '$2' $1 times"
    for (( i=0; i<=$1;i++ ))
    do
        printf $2
    done
}

# prints a string with right padding to fill allocated space
function PadRight() {
    local strLen=${#2}
    local str=$2
    local charsAlloc=$1
    if [ $strLen -le $charsAlloc ];
    then
        local padding=$[charsAlloc - strLen]
        printf $str 2> /dev/null
        printf "%*s" $padding
    fi
}

# Y/N prompt for specifed message
function Prompt() {
	echo $1
	while [ 1 ]
	do
		# prompt user
		printf '[yes/no]: '
		read input

		# loop until detect valid input
		if [[ $input == 'yes' ]];
		then
            Log "SUCCESS" "Recived 0 ( yes ) for prompt '$1'"
			return 0 # 0 for no error
		elif [[ $input == 'no' ]];
		then
			return 1
            Log "SUCCESS" "Recived 1 ( no ) for prompt '$1'"
		fi
        Log "ERROR" "User input parse failed -> repeating prompt" "malformed input" "'yes' or 'no'"
	done
}

function Validate() {
    if [[ -d $1 ]];
    then
        return 0
    fi
    return 1
}

function Compress() {
    local path=$1
    Validate $path
    if [ $? -eq 0 ];
    then
        echo ; echo "Input valid -> Compressing"
        Log "SUCCESS" "provided directory is valid -> attempting to compress"
        local directory=$(basename $path)
        tar -czf $directory.tar.gz $path 2> /dev/null
        local err=$?
        if [ $err -eq 0 ];
        then
            echo "Compression Successfull -> Created $directory.tar.gz"
            Log "SUCCESS" "successfully compressed $directory"
            return 0
        else
            echo "Compression failed!"
            Log "ERROR" "Compression failed" "tar command exited with code $err" "expect code 0"
            return 1
        fi
    else
        echo "Error: Could not process directory"
        Log "ERROR" "Could not process '$directory'" "check path" "valid directory"
        return 1
    fi
}

function AskForInput() {
    Log "UPDATE" "No paramaters provided -> Asking for input"
    local file
    echo Please provide a directory to compress:
    while [ ! $path ];
    do
        printf ' file > '
        read path
    done
    Compress $path
    return $?
}

function main() {
    local err
    timestamp=$(date +%Y-%m-%d@%H:%M:%S) # set timestamp for log file
    Log "UPDATE" "Script executed at $timestamp"
    if [ $# -eq 0 ];
    then
        AskForInput
        err=$?
    elif [ $# -eq 1 ];
    then
        Compress $1
        err=$?
    else
        Log "ERROR" "too many arguments" "too many script invocation arguments" "./backupScript.sh <filepath>"
        echo "ERROR: Too many arguments"
        err=1
    fi
    Log "UPDATE" "Script terminated at $(date +%Y-%m-%d@%H:%M:%S)"
    return $err
}

main $1 $2
exit $?

