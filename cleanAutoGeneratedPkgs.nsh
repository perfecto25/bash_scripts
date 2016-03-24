#!/bin/nsh
# 2016, BSA 8.5
# This script deletes auto-generated blpackages, to clean up depot and DB space


blcli_connect


BLPKG_FOLDER=$1
 
blcli_execute DepotObject listAllByGroup "${BLPKG_FOLDER}" > /dev/null 2>&1
blcli_storeenv LISTALL 


COUNT=0
PACKAGE=""

for PART in $LISTALL
do
	
	if [ $COUNT = 0 ]
	then
		PACKAGE="${PACKAGE}${PART}"
		COUNT=$((COUNT + 1))
	fi
	
	if [ $COUNT = 2 ]
	then
		PACKAGE="${PACKAGE}${PART}"

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
		unset PACKAGE
	fi

	if [ "${PART}" = "@" ]
	then
		PART=" @ "
		PACKAGE="${PACKAGE}${PART} "
		COUNT=$((COUNT + 1))
	fi
	
done

 
 
blcli_disconnect
