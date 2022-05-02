#!/bin/bash

#
#	OSC BASH SCRIPT ASSIGNMENT 2022 S1
#	TASK TWO
#
#	AARDHYN LAVENDER
#

input='' # global variable to store user input in
# I use this because if a functions return value is piped
# echo, printf, and read stop using stdout and stdin.
# this prevents me from reading input.

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
    echo
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
		read promptInput

		# loop until detect valid input
		if [[ $promptInput == 'yes' ]];
		then
            Log "SUCCESS" "Recived 0 ( yes ) for prompt '$1'"
			return 0 # 0 for no error
		elif [[ $promptInput == 'no' ]];
		then
            Log "SUCCESS" "Recived 1 ( no ) for prompt '$1'"
			return 1
		fi
        Log "ERROR" "User input parse failed -> repeating prompt" "malformed input" "'yes' or 'no'"
	done
}

# requests input from the user
function Input() {
    echo $1:
    input='' # void the global input variable
    while [ ! $input ];
    do
        printf ' > '
        read input
    done
    Log "SUCCESS" "Recived input of '$input' from question '$1'"
    return 0
}

 # Validates a directory
function Validate() {
    if [[ -d $1 ]];
    then
        return 0
    fi
    return 1
}

# compresses the provided file for transfer
function Compress() {
    local path=$1
    Validate $path
    if [ $? -eq 0 ];
    then
        echo ; echo "Input valid -> Compressing"
        Log "SUCCESS" "provided directory is valid -> attempting to compress"

        local directory=$(basename $path)
        local compressed=$directory.tar.gz

        tar -czf $compressed $path 2> /dev/null
        local err=$?
        if [ $err -eq 0 ];
        then
            echo Compression Successfull -\> Created $compressed
            Log "SUCCESS" "successfully compressed $directory to $compressed"
            Transfer $compressed
            return $?
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

# validates connectivity with a remote device
function Connectivity() {
    local ip=$1
    local stdpkts=3
    printf "\n\tEstablishing a connection with the remote server... "
    Log "UPDATE" "Validating connectivity of ip '$ip'"
    ping -c $stdpkts $ip &> /dev/null
    local err=$?
    if [ $err -eq 0 ];
    then
        printf "Success!\n"
        Log "SUCCESS" "Connection established"
        return 0;
    else
        printf "Failed!\n\n"
        Log "ERROR" "Failed to establish a connection" "'$ip' ping returned an exit code of $err" "Valid ip address"
        return 1;
    fi
}

# transfers a file to a remote server
function Transfer() {
    echo; Prompt "Do you wish to backup the file?"
    if [ $? -ne 0 ];
    then
        return 0
    fi

    local file=$1

    echo ; Repeat 70 '-'
    echo " Preparing to backup '$1' to remote server"
    Repeat 70 '-' ; echo
    Input "Username"
    echo ; local user=$input

    # ensure valid ip
    local valid=0
    while [ $valid -eq 0 ]
    do
        Input "Ip address (ipv4)"
        local ip=$input
        Connectivity $ip && valid=1
    done

    # ensure valid port number
    local validPort=0;
    while [ $validPort -eq 0 ]
    do
        echo ; Input "Port number"
        port=$input
        if [[ $port -lt 1 || $port -gt 65535 ]];
        then
            printf "\n\tInvalid Port!\n"
        else
            validPort=1
        fi
    done

    echo ; Input "Destination Filepath"
    local dstfp=$input
    echo ; Repeat 70 '-' ; echo

    printf "\tInitiating secure copy to server"
    echo ; echo

    scp -r -P $port $file $user@$ip:"$dstfp" &> /dev/null
    local err=$?
    if [ $err -eq 0 ];
    then
        echo Transfer Successfull!
    else
        echo Transfer Failed!
    fi
    echo ; Repeat 70 '-' ; echo
}

# asks the user for the script input
function AskForInput() {
    Log "UPDATE" "No paramaters provided -> Asking for input"
    echo Please provide a directory to backup:
    while [ ! $path ];
    do
        printf ' file > '
        read path
    done
    Compress $path
    return $?
}

# script entry point
function Main() {
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

Main $1 $2
exit $?

