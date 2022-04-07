#!/bin/bash

#
#	OSC BASH SCRIPT ASSIGNMENT 2022S1
#	TASK ONE
#
#	AARDHYN LAVENDER
#

# reads data stored in a remote CSV file
function ReadRemote() {
	local url=$1
	
	# for now... echo the url
	echo $url
}

# reads data stored in a local CSV file
function ReadLocal() {
	local filepath=$1

	# for now... print the contents of the file
	cat $filepath
}

function ValidateURL() {
	local url=$1
	
	# check there is a url to validate
	if [[ $url ]];
	then # ensure url is not malformed
		local HTTP='http://'
		local HTTPS='https://'

		if [[ ${url:0:7} == $HTTP || ${url:0:8} == $HTTPS ]];
		then
			ReadRemote $url
		else
			echo ERR: url was malformed!
			echo 'use:	http://<path>'
			echo 'use:	https://<path>'
		fi
	else 
		echo ERR: no url was specified!
	fi
}

# Checks the script input is valid
function ValidateArgInput() {
	if [[ $1 == '-r' ]];
	then # user has specified remote file input
		ValidateURL $2
	elif [[ -f $1 ]];
	then # user has specifed a local file to read
		ReadLocal $1
	elif [[ -d $1 ]];
	then # user has specified a directory
		echo ERR: local input must point to a file!
	else # who knows whats been inputed!
		echo ERR: invalid input!
		echo 'use:	<command> <filepath>'
		echo 'use:	<command> -r <url>'
	fi
}

function AskForInput() {
	# for now.. tell the user it will ask for input
	echo asking for input...
}

if [ "$#" -eq 0 ];
then
	AskForInput
else
	ValidateArgInput $1 $2
fi
exit 0

