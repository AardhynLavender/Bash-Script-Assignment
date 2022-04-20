#!/bin/bash

file=createdusers
if [[ -f $file ]];
then
	echo deleting users. ; echo
	while IFS= read -r user
	do
		echo deleting: $user.
		if [[ $(id -u $user 2> /dev/null) ]];
		then
			sudo userdel -rf $user
			echo " 	deletion successfull."
		else
			echo "	user does not exist!"
		fi
		echo
	done < $file
else
	echo failed to find file!
fi

# removed shared directories
if [ -d /visitorData ];
then sudo rm -r /visitorData
fi
if [ -d /staffData ];
then sudo rm -r /staffData
fi

