#!/bin/nsh
# 2016, BSA 8.5
# This script deletes auto-generated blpackages, to clean up depot and DB space


blcli_connect


BLPKG_FOLDER=$1
 
blcli_execute DepotObject listAllByGroup ${BLPKG_FOLDER} > /dev/null 2>&1
blcli_storeenv LISTALL 


for BLPKG_NAME in $LISTALL
do
	### check if BLPKG_NAME is auto-generated
	blcli_execute DepotObject getFullyResolvedPropertyValue BLPACKAGE ${BLPKG_FOLDER} ${BLPKG_NAME} AUTO_GENERATED > /dev/null 2>&1
	blcli_storeenv AUTO_GEN
	
	echo "--- Processing package: ${BLPKG_NAME}, AUTO_GENERATED: ${AUTO_GEN}"
	
	if [ "${AUTO_GEN}" = true ]
	then
		echo "-- Deleting package: ${BLPKG_NAME}"
		blcli_execute BlPackage deleteBlPackageByGroupAndName ${BLPKG_FOLDER} ${BLPKG_NAME}
		
	fi
	
done

 
 
blcli_disconnect
