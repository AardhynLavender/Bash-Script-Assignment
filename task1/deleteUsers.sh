#!/bin/bash

file=$1
if [[ -f $file ]];
then
	echo deleting users. ; echo
	while IFS= read -r user
	do
		echo deleting: $user.
		if [[ $(id -u $user 2> /dev/null) ]];
		then
			sudo userdel $user
			sudo rm -r "/home/$user"
			echo " 	deletion successfull."
		else
			echo "	user does not exist!"
		fi
		echo
	done < $file
else
	echo failed to find file!
fi
