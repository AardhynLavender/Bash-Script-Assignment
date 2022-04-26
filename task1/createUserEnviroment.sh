#!/bin/bash

#
#	OSC BASH SCRIPT ASSIGNMENT 2022 S1
#	TASK ONE
#
#	AARDHYN LAVENDER
#

# Logs details of the current script execution to a file
function Log() {
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
    Log "UPDATE" "Authenticating script invoker"
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
        Log "SUCCESS" "File conforms to schema -> Parsing"
		echo 'File conforms to schema'

		# dev - log users created from this script
		rm createdusers 2> /dev/null

        Authenticate
		if [ $? -ne 0 ];
        then
            Log "ERROR" "Script authentication failed"
            echo "ERROR: Authentication Failed"
            return 1;
        fi
        Log "SUCCESS" "Script invoker has been authenicated -> granted sudo permissions"

        local userCount=$(wc -l < $file)
        echo ; echo "Found $userCount users."
        Prompt 'Do you want to create these users?'

        if [ $? -eq 0 ];
        then # proceed to create users
            Log "UPDATE" "Attempting to create $userCount users from file"
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
                        Log "SUCCESS" "Username creation successfull -> created $username"
                        PadRight 20 $username

                        local password=$(CreatePassword $dob)
                        if [[ $password ]];
                        then # proceed with user creation
                            Log "SUCCESS" "Password created -> created $password"
                            PadRight 10 "success"

                            # encrypt password
                            local encrypted=$(openssl passwd -crypt $password)

                            # create user
                            sudo useradd -md "/home/$username" -s /bin/bash -p $encrypted $username 2>/dev/null
                            local useraddCode=$?
                            echo $username >> createdusers # log created user

                            if [ $useraddCode -eq 0 ];
                            then # everything worked!
                                Log "SUCCESS" "Created $username"

                                PadRight 10 'created'
                                PadRight 20 "/home/$username"

                                local addedGroups=""
                                local isSudo=0;

                                local IFS=',' # reset IFS
                                for group in ${groups//, /}
                                do # loop groups
                                    if [ $group == 'sudo' ];
                                    then # add to sudo, and create alias
                                        Log "UPDATE" "$username requests sudo access"
                                        isSudo=1;
                                        sudo usermod -a -G sudo $username
                                        if [ $? -eq 0 ];
                                        then
                                            Log "SUCCESS" "Added $username to sudoers"
                                        else
                                            Log "ERROR" "Failed to add $username to sudos" "ln194"
                                        fi
                                    fi

                                    if [[ ! $(grep "^$group:" /etc/group) ]];
                                    then # add to group
                                        Log "UPDATE" "Group does not exist -> creating"
                                        sudo groupadd $group
                                    fi

                                    Log "UPDATE" "Attempting to add $username to $group"
                                    sudo usermod -a -G $group $username

                                    # log success of group addition
                                    if [ $? -eq 0 ];
                                    then
                                        addedGroups="${addedGroups} ${group}"
                                        Log "SUCCESS" "Added $username to $group"
                                    else
                                        addedGroups="${addedGroups} !${group}!"
                                        Log "ERROR" "Failed to add $username to $group" "ln210"
                                    fi
                                done
                                local IFS=';' # return for base loop IFS

                                Log "UPDATE" "Group additions for $username complete"

                                # determine alias
                                if [ $isSudo -eq 1 ];
                                then
                                    sudo bash -c "echo alias myls=\'ls -lisa /home/$username\' >> /home/$username/.bash_aliases"
                                    if [ $? -eq 0 ];
                                    then
                                        PadRight 10 'success'
                                        Log "SUCCESS" "Added myls alias to $username"
                                    else
                                        PadRight 10 'failed'
                                        Log "ERROR" "Could not create myls alias to $username" "ln229"
                                    fi
                                else
                                    Log "UPDATE" "Skipped adding alias to $username"
                                    PadRight 10
                                fi

                                # display groups
                                PadRight 30 $addedGroups

                                # does user require access to shared folder
                                if [ $folder ];
                                then # shared folder has been specified
                                    Log "UPDATE" "$username requires access to $folder"
                                    local access="${folder:1}Access"

                                    if [ ! -d $folder ];
                                    then # create shared folder
                                        Log "UPDATE" "Directory does not yet exist -> creating"
                                        # create shared folder
                                        sudo mkdir $folder
                                        sudo chmod 770 $folder
                                        if [ -d $folder ];
                                        then
                                            Log "SUCCESS" "Created $folder"
                                        fi

                                        # does access already exist
                                        if [[ ! $(grep "^$access:" /etc/group) ]];
                                        then # create
                                            Log "UPDATE" "Access group for $folder does not exist -> creating"
                                            sudo groupadd $access
                                        fi

                                        # assign ownership
                                        sudo chown root:$access $folder
                                        if [ $? -eq 0 ];
                                        then
                                            Log "SUCCESS" "Assigned $access to $folder"
                                        else
                                            Log "ERROR" "Could not assign $access to $folder" "ln271"
                                        fi
                                    fi

                                    # grant access
                                    sudo usermod -a -G $access $username
                                    if [ $? -eq 0 ];
                                    then
                                        PadRight 30 "Access to $folder"
                                        Log "SUCCESS" "$username has access to $folder"
                                    else
                                        PadRight 30 "Access Failed"
                                        Log "ERROR" "Failed to give $username access to $folder" "ln281"
                                    fi

                                    # provide link
                                    sudo ln -s /$folder /home/$username/shared
                                    if [ $? -eq 0 ];
                                    then
                                        PadRight 10 "Linked"
                                        Log "SUCCESS" "Provided $username a link to $folder"
                                    else
                                        PadRight 10 "Failed"
                                        Log "ERROR" "Could not provide $username a link to $folder" "ln292"
                                    fi
                                fi
                            elif [ $useraddCode -eq 9 ];
                            then # user already registered with $username
                                PadRight 10 'failed'
                                Log "ERROR" "User Creation Failed" "A user is already registered under $username" "unique username"
                            else # somthing bad happened, provide the err code
                                10 'failed'
                                Log "ERROR" "User creation failed" "command exited with code $useraddCode" "exit code of 0"
                            fi
                            echo
                        else # log err then continue
                            PadRight 10 'failed'
                            Log "ERROR" "Failed to create password from date of birth $dob" "check ln$linenumber of input file" "valid date of birth"
                            continue;
                        fi
                    else # log err then continue
                        PadRight 20 'failed'
                        Log "ERROR" "Failed to create username from email $email" "check ln$linenumber of input file"
                        continue
                    fi
                fi
            done < $file
            Repeat 150 "=" ; echo
            Log "UPDATE" "Parse complete"
        else
            echo ; echo Aborting user creation
            Log "UPDATE" "User creation was aborted"
        fi

		# ask if the file should be deleted
        echo ; echo "Parse complete"
		Prompt 'Do you want to delete the file?' && rm $file
	else # the file is either !csv or data is malformed
        Log "ERROR" "File did not match required schema" "found $header" "schema $schema"
		echo ERROR: File did not match required schema!
		echo "TRACE:	found $header"
		echo "EXPECT:	$schema"

		# the user may wish to keep the invalid file...
		Prompt "Do you want to delete the file?" && rm $file
	fi

}

# Attempt to fetch remote data
function ReadRemote() {
	local url=$1
	# get data from url
    Log "UPDATE" "Fetching data from remote source into 'fetchedData'"
	wget $url -O fetchedData 2> /dev/null
	if [[ $? -ne 0 ]];
	then # wget encountered an error
        Log "ERROR" "File could not be downloaded" "validate $url using 'wget' ( man wget )"
		echo ERROR: File could not be downloaded!
	else # read data
        Log "UPDATE" "wget was successfull -> validating returned data"
		if [[ -f fetchedData ]];
		then # attempt to read data
            Log "SUCCESS" "File was retrived from $url -> Attempting to parse"
			echo success! Attempting to parse
			ReadCSV fetchedData
		else
            Log "ERROR" "No file was returned from $url" "validate $url using 'wget' ( man wget )"
			echo ERROR: No file was returned!
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
            Log "SUCCESS" "Valid url was passed"
            Log "UPDATE" "Attempting to read remote"
			ReadRemote $url
		else
            Log "ERROR" "Url was malformed" "malformed user input" "http://* || https://*"
			echo ERROR: url was malformed!
			echo 'use:	http://<path>'
			echo 'use:	https://<path>'
		fi
	else
        Log "ERROR" "URL was not specified" "invalid user input" "<command> -r <url>"
		echo ERROR: no url was specified!
		echo "EXPECT:	<command> -r <url>"
	fi
}

# Valiate input points to a valid file
function ValidateFilepath() {
	if [[ -f $1 ]];
	then # user has specifed a local file to read
        Log "UPDATE" "File is valid -> attempting to parse"
		ReadCSV $1
	elif [[ -d $1 ]];
	then # user has specified a directory
        Log "ERROR" "Input must point to a file!" "invalid user input" "<command> <-f filepath>"
		echo ERROR: Input must point to a file!
		echo "EXPECT:	<command> <-f filepath>"
	else # who knows whats been specified...
        Log "ERROR" "A file must be specified" "invalid user input" "<command> <filepath>"
		echo ERROR: a file must be specified!
		echo "EXPECT:	<command> <filepath>"
	fi
}

# Determine function based on paramaters
function DetermineInput() {
	if [[ $1 == '-r' ]];
	then # user has specified remote file input
        Log "UPDATE" "Specifed remote -> validating"
		ValidateURL $2
	else # assume user wants to use a local file
        Log "UPDATE" "Specifed local -> validating"
		ValidateFilepath $1
	fi
}

# Prompts the user for script paramaters
function AskForInput() {
	Prompt "Do you wish to parse a local file?"
	if [ $? -eq 1 ];
	then
        Log "UPDATE" "Specifed remote -> reading"
		echo Parsing remote
		printf "Enter the url: "
		read url
        Log "UPDATE" "Recived input -> validating"
		ValidateURL $url
	else
        Log "UPDATE" "Specifed local -> reading"
		echo Parsing local
		printf "Enter the filepath: "
		read filepath
        Log "UPDATE" "Recived input -> validating"
		ValidateFilepath $filepath
	fi

}

# application entry point
function Main() {
    timestamp=$(date +%Y-%m-%d@%H:%M:%S) # set timestamp for log file
    Log "UPDATE" "Script executed at $timestamp"
	if [ "$#" -eq 0 ];
	then
        Log "UPDATE" "No script arguments provided -> asking for input"
		AskForInput
	else
        Log 'UPDATE' 'Script arguments provided -> validating arguments'
		DetermineInput $1 $2
	fi
    Log "UPDATE" "Script terminated at $(date +%Y-%m-%d@%H:%M:%S)"
	exit 0
}

Main $1 $2

