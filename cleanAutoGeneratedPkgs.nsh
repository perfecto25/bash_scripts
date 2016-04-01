#!/bin/nsh
# 2016, BSA 8.5
# This script deletes auto-generated blpackages, to clean up depot and DB space, only works for packages in the
# following format name:  "prefix remediation job @ date time"
# blcli limitation will return package name, but if there is a space in the name, it will break it into a separate object
# for example "RedHat 6 remediation job @ 2015-12-20 08-44-34" will be 6 different returned objects because of space char
# this script uses COUNT and AMPERSIGN vars to parse and complile the name of the package, then deletes the package


blcli_connect


BLPKG_FOLDER=$1
 
blcli_execute DepotObject listAllByGroup "${BLPKG_FOLDER}" > /dev/null 2>&1
blcli_storeenv LISTALL 

AMPERSIGN=0
COUNT=0
PACKAGE=""
	
for PART in $LISTALL
do
	
	if [ $AMPERSIGN = 0 ]
	then
		PACKAGE="${PACKAGE} ${PART}"
	fi

	if [ $AMPERSIGN = 1 ] && [ $COUNT != 2 ]
	then
		PACKAGE="${PACKAGE} ${PART}"
		COUNT=$((COUNT + 1))
	fi
	
	
	if [ "${PART}" = "@" ]
	then
		AMPERSIGN=1
	fi
	
	if [ $AMPERSIGN = 1 ] && [ $COUNT = 2 ]
	then
		
		# remove double white space
		PACKAGE=`echo $PACKAGE | tr -s ' '`
		
		### check if BLPKG_NAME is auto-generated
		blcli_execute DepotObject getFullyResolvedPropertyValue BLPACKAGE "${BLPKG_FOLDER}" "${PACKAGE}" AUTO_GENERATED > /dev/null 2>&1 
		blcli_storeenv AUTO_GEN
	
		echo "--- Processing package: ${PACKAGE}, AUTO_GENERATED: ${AUTO_GEN}"
	
		if [ "${AUTO_GEN}" = true ]
		then
			echo "-- Deleting package: ${PACKAGE}"
			blcli_execute BlPackage deleteBlPackageByGroupAndName "${BLPKG_FOLDER}" "${PACKAGE}"
		fi
		
		COUNT=0
		AMPERSIGN=0
		unset PACKAGE
	fi

done

 
 
blcli_disconnect