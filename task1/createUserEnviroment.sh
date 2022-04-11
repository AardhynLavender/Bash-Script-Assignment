#!/bin/bash

#
#	OSC BASH SCRIPT ASSIGNMENT 2022S1
#	TASK ONE
#
#	AARDHYN LAVENDER
#

# binary prompt of specifed message
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
			return 0 # 0 for no error -- intended to be used in piping...
		elif [[ $input == 'no' ]];
		then
			return 1
		fi
	done
}

# reads data stored in a local CSV file
function ReadCSV() {
	local file=$1	
	local IFS=';'
	local linenumber=0
	
	# validate data conforms to schema
	local schema='e-mail;birth date;groups;sharedFolder'
	local header=$(cat $file | head -n 1)
	if [[ "$header" == "$schema" ]];
	then # read and parse data
		echo File conforms to schema... parsing.
		while read email dob groups folder
		do
			if [[ $linenumber -ne 0 ]];
			then
				echo "email:	$email"
				echo "dob:	$dob"
				echo "groups:	$groups"
				echo "folder:	$folder"
				echo
			fi
			((++linenumber))
		done < $file

		# ask if the file should be deleted 	
		Prompt "Parse Complete... do you want to delete the file?" && rm $file
	else # the file is either !csv or data is malformed
		echo ERR: File did not match required schema!	
		echo "FOUND:	$header"
		echo "EXPECT:	$schema"

		# the user may wish to keep the invalid file...
		Prompt "Do you want to delete the file?" && rm $file
	fi
			
}

# reads data stored in a remote CSV file
function ReadRemote() {
	local url=$1
	# get data from url
	wget $url -O fetchedData 2> /dev/null
	local err=$?

	if [[ $err -ne 0 ]];
	then # wget encountered an error
		echo ERR: File could not be downloaded!
	else # read data
		if [[ -f fetchedData ]];
		then # attempt to read data
			echo success! Attempting to parse
			ReadCSV fetchedData 
		else
			echo ERR: no file was returned!
		fi
	fi
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
		echo "EXPECT:	<comand> -r <url>"
	fi
}

function ValidateFilepath() {
	if [[ -f $1 ]];
	then # user has specifed a local file to read
		ReadCSV $1
	elif [[ -d $1 ]];
	then # user has specified a directory
		echo ERR: Input must point to a file!
		echo "EXPECT:	<commaned <-f filepath>"
	else
		echo ERR: A file must be specified!
		echo "EXPECT:	<command> <filepath>"
	fi
}

# determines the command line input of the command
function DetermineInput() {
	if [[ $1 == '-r' ]];
	then # user has specified remote file input
		ValidateURL $2
	else # assume user wants to use a local file
		ValidateFilpath $1
	fi
}

# prompts the user for script paramaters
function AskForInput() {
	Prompt "Do you wish to parse a local file?"
	if [ $? -eq 1 ];
	then
		echo parsing remote
		printf "Enter the url: "
		read url
		ValidateURL $url
	else
		echo parsing local
		printf "Enter the filepath: "
		read filepath
		ValidateFilepath $filepath		
	fi

}

if [ "$#" -eq 0 ];
then
	AskForInput
else
	DetermineInput $1 $2
fi
exit 0

