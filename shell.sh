#!/bin/bash

paramScript=$1
source functionScript.sh

if (echo "$1" | grep -E -q "^?[0-9]+$"); then
	echo ""
else 
	echo "Error: Not Number"
	exit 0
fi
MyAuthorization
echo "Request a list of repositories"
ListRep
repository_handler $paramScript
removeFiles
exit 0 
