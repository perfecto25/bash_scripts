#!/bin/bash
# This script will parse all .yaml files in current dir and check syntax
# requires Ruby to installed on system
# usage: ./yamlcheck.sh /path/to/dir


## check dir
if [ -z ${1} ]
then
	echo "Please provide directory for yaml files"
	exit 1
fi

cd $1

for YAMLFILE in *
do	
	EXT=`echo $YAMLFILE | awk -F\. {'print $2'}`

	if [ "${EXT}" == "yaml" ] && [[ -f $YAMLFILE ]]
	then
		echo "--- Checking syntax of ${YAMLFILE}" 
		ruby -e "require 'yaml'; YAML.load_file('${YAMLFILE}')"
	
       		if [ $? = 1 ]
		then
			echo "ERROR: ${YAMLFILE} has syntax errors"
		else
			echo "${YAMLFILE} syntax is ok"
		fi
	fi
done;
