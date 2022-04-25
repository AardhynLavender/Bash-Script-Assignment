#!/bin/bash

#
#	OSC BASH SCRIPT ASSIGNMENT 2022S1
#	TASK ONE
#
#	AARDHYN LAVENDER
#

function Repeat() {
    for (( i=0; i<=$1;i++ ))
    do
        printf $2
    done
}

# prints a string with right padding
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

# Binary prompt for specifed message
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

# create a username from an email address
function CreateUsername() {
	local email=$1
	if [[ ! $email ]]; then return 1; fi

	# extract first and last name
	local fullname=$(echo $email | cut -d '@' -f1)
	local first=$(echo $fullname | cut -d '.' -f1)
	local last=$(echo $fullname | cut -d '.' -f2)

	# create username with the "<lastname[0]><firstname>" convention
	echo "${last:0:1}$first"
	return 0
}

# Creates a password from a date
function CreatePassword() {
	local dob=$1
	if [[ ! $dob ]] ; then return 1; fi
	local password=$(date -d $dob +%m%Y)
	echo $password
}

# Ask for users password
function Authenticate() {
	echo ; echo Script may require Sudo Permissions
    sudo ls > /dev/null # ...force sudo password
	return $?
}

# Read data in a local CSV file
function ReadCSV {
	local file=$1
	local IFS=';'
	local linenumber=0

	# validate data conforms to schema
	local schema='e-mail;birth date;groups;sharedFolder'
	local header=$(cat $file | head -n 1)
	if [[ "$header" == "$schema" ]];
	then # read and parse data
		echo 'File conforms to schema -> parsing.'

		# dev - log users created from this script
		rm createdusers 2> /dev/null

        Authenticate
		if [ $? -ne 0 ];
        then
            echo "ERR: Authentication Failed"
            return 1;
        fi

        local userCount=$(wc -l < $file)
        echo ; echo "Found $userCount users."
        Prompt 'Do you want to create these users?'

        if [ $? -eq 0 ];
        then # proceed to create users
            echo ; echo Creating $userCount users:
            # print column headings
            echo
            PadRight 20 'USERNAME'
            PadRight 10 'PASSWORD'
            PadRight 10 'USER'
            PadRight 20 'HOME DIRECTORY'
            PadRight 10 'ALIAS'
            PadRight 30 ' GROUPS'
            PadRight 30 'SHARED DIRECTORY'
            PadRight 20 'DIRECTORY LINK'
            echo
            Repeat 150 "=" ; echo

            while read email dob groups folder
            do
                ((++linenumber))
                if [[ $linenumber -ne 1 ]];
                then # parse line
                    # create username from email
                    local username=$(CreateUsername $email)
                    if [[ $username ]];
                    then # proceed with user creation...
                        #echo Create username success!
                        #echo Created:	$username

                        PadRight 20 $username

                        local password=$(CreatePassword $dob)
                        if [[ $password ]];
                        then # proceed with user creation
                            #echo Create password success!
                            #echo Created:	$password

                            PadRight 10 "success"

                            # encrypt password
                            local encrypted=$(openssl passwd -crypt $password)

                            # create user
                            sudo useradd -md "/home/$username" -s /bin/bash -p $encrypted $username 2>/dev/null
                            local useraddCode=$?
                            echo $username >> createdusers # log created user

                            if [ $useraddCode -eq 0 ];
                            then # everything worked!
                                #echo User creation successful

                                PadRight 10 'created'
                                PadRight 20 "/home/$username"

                                local addedGroups=""
                                local isSudo=0;

                                local IFS=',' # reset IFS
                                for group in ${groups//, /}
                                do # loop groups
                                    if [ $group == 'sudo' ];
                                    then # add to sudo, and create alias
                                        #echo 'is sudo'
                                        isSudo=1;
                                        sudo usermod -a -G sudo $username
                                    fi

                                    if [[ $(grep "^$group:" /etc/group) ]];
                                    then # add to group
                                        #echo Found $group
                                        sudo usermod -a -G $group $username
                                    else # create then add to group
                                        #echo Did not find $group, creating
                                        sudo groupadd $group
                                        sudo usermod -a -G $group $username
                                    fi

                                    # log success of group addition
                                    if [ $? -eq 0 ];
                                    then
                                        addedGroups="${addedGroups} ${group}"
                                    else
                                        addedGroups="${addedGroups} !${group}!"
                                    fi

                                done
                                local IFS=';' # return for base loop IFS

                                # determine alias
                                if [ $isSudo -eq 1 ];
                                then
                                    sudo bash -c "echo alias myls=\'ls -lisa /home/$username\' >> /home/$username/.bash_aliases"
                                    if [ $? -eq 0 ];
                                    then
                                        PadRight 10 'success'
                                    else
                                        PadRight 10 'failed'
                                    fi
                                else
                                    PadRight 10
                                fi

                                # display groups
                                PadRight 30 $addedGroups

                                # does user require access to shared folder
                                if [ $folder ];
                                then # shared folder has been specified
                                    #echo Has shared folder access
                                    local access="${folder:1}Access"

                                    if [ ! -d $folder ];
                                    then # create shared folder
                                        #echo !exists
                                        # create shared folder
                                        sudo mkdir $folder
                                        sudo chmod 770 $folder

                                        # does access already exist
                                        if [[ ! $(grep "^$access:" /etc/group) ]];
                                        then # create
                                            sudo groupadd $access
                                        fi

                                        # assign ownership
                                        sudo chown root:$access $folder
                                    fi

                                    # grant access
                                    sudo usermod -a -G $access $username
                                    if [ $? -eq 0 ];
                                    then
                                        PadRight 30 "Access to $folder"
                                    else
                                        PadRight 30 "Access Failed"
                                    fi

                                    # provide link
                                    sudo ln -s /$folder /home/$username/shared
                                    if [ $? -eq 0 ];
                                    then
                                        PadRight 10 "Linked"
                                    else
                                        PadRight 10 "Failed"
                                    fi
                                fi
                            elif [ $useraddCode -eq 9 ];
                            then # user already registered with $username
                                PadRight 10 'failed'
                                #echo ; echo
                                #printf "\tERR: User Creation Failed! A user is already registered with a username of $username\n"
                            else # somthing bad happened, provide the err code
                                PadRight 10 'failed'
                                #printf "\tERR: User creation failed!\n"
                                #printf "\tTRACE: command exited with code $useraddCode\n"
                            fi
                            echo
                        else # log err then continue
                            PadRight 10 'failed'
                            #echo ERR: failed to create password from dob!
                            #echo TRACE: 	Check ln$linenumber.
                            #echo SKIPPING; echo
                            continue;
                        fi
                    else # log err then continue
                        PadRight 20 'failed'
                        #echo ERR: failed to create username!
                        #echo TRACE: 	Check ln$linenumber.
                        #echo SKIPPING ; echo
                        continue
                    fi
                fi
            done < $file
            Repeat 150 "=" ; echo
        else
            echo ; echo Aborting user creation
        fi

		# ask if the file should be deleted
        echo ; echo "Parse complete"
		Prompt 'do you want to delete the file?' && rm $file
	else # the file is either !csv or data is malformed
		echo ERR: File did not match required schema!
		echo "FOUND:	$header"
		echo "EXPECT:	$schema"

		# the user may wish to keep the invalid file...
		Prompt "Do you want to delete the file?" && rm $file
	fi

}

# Attempt to fetch remote data
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

# Validate url format
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

# Valiate input points to a valid file
function ValidateFilepath() {
	if [[ -f $1 ]];
	then # user has specifed a local file to read
		ReadCSV $1
	elif [[ -d $1 ]];
	then # user has specified a directory
		echo ERR: Input must point to a file!
		echo "EXPECT:	<commaned <-f filepath>"
	else # who knows whats been specified...
		echo ERR: A file must be specified!
		echo "EXPECT:	<command> <filepath>"
	fi
}

# Determine function based on paramaters
function DetermineInput() {
	if [[ $1 == '-r' ]];
	then # user has specified remote file input
		ValidateURL $2
	else # assume user wants to use a local file
		ValidateFilepath $1
	fi
}

# Prompts the user for script paramaters
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

# application entry point
function Main() {
	if [ "$#" -eq 0 ];
	then
		AskForInput
	else
		DetermineInput $1 $2
	fi
	exit 0
}

Main $1 $2

