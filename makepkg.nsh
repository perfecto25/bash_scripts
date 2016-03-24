#!/bin/nsh
# type 1
# set targetto appserver
#
# scriptparameters

function handleError()	{
	if [ "$?" = "0" ]; then
		echo "passed"
	else
		echo "$2 failed with exit code $1"
		exit $1
	fi
}


blcli_connect

FEED_FILE=$1
CT_FOLDER=$2
CT_NAME=$3
SOURCE=$4
FEEDFILE_DIR=$5
INSTALL_DIR=$6
TARGET=$7

 
echo "feed file is $FEED_FILE"
 
echo "folder path is $CT_FOLDER"

echo "package name is $CT_NAME"
 
echo "source server is $SOURCE"

echo "Bladelogic Depot path: $CT_FOLDER"

echo "Target install DIR is: $INSTALL_DIR"

blcli_execute TemplateGroup groupNameToId $CT_FOLDER
blcli_storeenv CT_FOLDER_KEY
echo "component template folder DB Key is" $CT_FOLDER_KEY

# create a component template & store its DB Key
blcli_execute Template createEmptyTemplate $CT_NAME $CT_FOLDER_KEY true
blcli_storeenv CT_KEY
echo "component template DB Key is" $CT_KEY
 
 
 
# get the list of files to add to the component template
LIST=`cat $FEED_FILE`
echo "files are:" $LIST

 
# add the files to the component template & store its updated DB Key for the next file add
for ITEM in $LIST
                do

 blcli_execute Template addFilePart $CT_KEY $ITEM false false false false false false false false false
               
                blcli_storeenv NEW_CT_KEY 
                CT_KEY=$NEW_CT_KEY
                echo "revised component template DB Key is" $CT_KEY
                echo "adding next file in list..."

                
done


 
# get the ID of the job folder for the discover job
blcli_execute JobGroup groupNameToId $CT_FOLDER
blcli_storeenv DJ_FOLDER_ID
echo "discover job folder ID is" $DJ_FOLDER_ID

 
# create and run a discover job on the component template
blcli_execute ComponentDiscoveryJob createComponentDiscoveryJob "$CT_NAME"_disc $DJ_FOLDER_ID $CT_KEY $SOURCE
blcli_storeenv DJ_KEY 
blcli_execute ComponentDiscoveryJob executeJobAndWait $DJ_KEY
echo "discover job is complete"
 
# get the ID of the source server
blcli_execute Server getServerDBKeyByName $SOURCE
blcli_storeenv SOURCE_KEY 
SOURCE_ID=`echo $SOURCE_KEY|awk -F'-' '{print $2}'`
echo "source ID is" $SOURCE_ID
 
# get the DB Key of the component from the discover job run
blcli_execute Component getAllComponentKeysByTemplateKey $CT_KEY
blcli_storeenv COMP_KEY
echo "component DB Key is" $COMP_KEY

 
# get the ID of the package folder
blcli_execute DepotGroup groupNameToId $CT_FOLDER
blcli_storeenv PKG_FOLDER_ID
echo "package folder DB Key is" $PKG_FOLDER_ID
 
# create the BLPackage & import the files from the component template into it
blcli_execute BlPackage createPackageFromComponent $CT_NAME $PKG_FOLDER_ID false false true true false $COMP_KEY
handleError $? "createPackageFromComponent"

echo " - adding MoveCmd"
PKG_DBKEY=`blcli BlPackage getDBKeyByGroupAndName $CT_FOLDER $CT_NAME`
EXTCMD_ADD=`blcli BlPackage addExternalCmdToEnd $PKG_DBKEY "mv files" //$SOURCE/$FEEDFILE_DIR/MoveCmd "" "Abort"`


echo " - adding ModuleCmd"
PKG_DBKEY=`blcli BlPackage getDBKeyByGroupAndName $CT_FOLDER $CT_NAME`
EXTCMD_ADD=`blcli BlPackage addExternalCmdToEnd $PKG_DBKEY "execute modules" //$SOURCE/$FEEDFILE_DIR/ModuleCmd "" "Abort"`

# create BLPackage deploy job
echo "creating deploy job"
SIMULATE=false
COMMIT=true
INDIRECT=false
OPTIONS="$SIMULATE $COMMIT $INDIRECT"
blcli_execute DeployJob createDeployJob "$CT_NAME Deploy" $DJ_FOLDER_ID $PKG_DBKEY $TARGET $OPTIONS


UNINST=${CT_NAME}_Uninstall
## create Uninstall BLPackage & Deploy Job
blcli_execute BlPackage createEmptyPackage $UNINST "Uninstall" $PKG_FOLDER_ID
## add uninstall cmd to package
PKG_DBKEY2=`blcli BlPackage getDBKeyByGroupAndName $CT_FOLDER $UNINST`
echo "PKG_DBKEY2 is $PKG_DBKEY2"
EXTCMD_ADD=`blcli BlPackage addExternalCmdToEnd $PKG_DBKEY2 Uninstall //$SOURCE$FEEDFILE_DIR/UninstallCmd "" "Abort"`
## add Uninstall deploy job
echo "creating uninstall deploy job"
SIMULATE=false
COMMIT=true
INDIRECT=false
OPTIONS="$SIMULATE $COMMIT $INDIRECT"
blcli_execute DeployJob createDeployJob $UNINST $DJ_FOLDER_ID $PKG_DBKEY2 $TARGET $OPTIONS

blcli_disconnect
