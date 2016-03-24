#!/bin/nsh
## this script runs OS Compliance against servers provided as arguments. 

# Description: run script like this 'nsh compliance.nsh server1 server 2 server3 etc' 
# Script takes each server as an argument, checks if the server is enrolled, if enrolled, it gets the Server OS name and creates temporary server groups based on OS name, adds the server to the group and then runs an OS-specific compliance job against the group

PARENT_GROUP="/Workspace/test"
DATESTAMP=$(date +%m%d%y%H%M%S)
PROFILE=default
UN=user
PW=pw

## set Exist flags to false, these are used to decide whether to execute Compliance job or not.
## if there are actual servers that match these OS, then flag will change to true.
RHEL5_SERVER_EXISTS='false'
RHEL6_SERVER_EXISTS='false'
SOL10_SERVER_EXISTS='false'

blcli_setjvmoption -Dcom.bladelogic.cli.execute.quietmode.enabled=true
blcli_setjvmoption -Dcom.bladelogic.cli.execute.addnewline.enabled=true

## authenticate
blcred cred -acquire -profile $PROFILE -username $UN -password $PW
blcli_setoption serviceProfileName $PROFILE
blcli_setoption roleName BLAdmins
blcli_connect



## create temporary Server Group for RHEL5, 6 and Solaris10
echo "creating Server group"
RHEL5_GROUP="RHEL5_$DATESTAMP"
RHEL6_GROUP="RHEL6_$DATESTAMP"
SOL10_GROUP="SOL10_$DATESTAMP"

blcli_execute StaticServerGroup createGroupWithParentName $RHEL5_GROUP $PARENT_GROUP
blcli_execute StaticServerGroup createGroupWithParentName $RHEL6_GROUP $PARENT_GROUP
blcli_execute StaticServerGroup createGroupWithParentName $SOL10_GROUP $PARENT_GROUP
echo ""

## parse thru servers:
for arg; do

  ## check if server is enrolled
  blcli_execute Server serverExists $arg
  blcli_storeenv SERVER_EXISTS
  
  if [ $SERVER_EXISTS = "true" ];
    then
      echo "server '$arg' is enrolled"
      
      ## get OS type
      blcli_execute Server getFullyResolvedPropertyValue $arg OS_VENDOR
      blcli_storeenv OS_VENDOR
            
      blcli_execute Server getFullyResolvedPropertyValue $arg OS_VERSION
      blcli_storeenv OS_VERSION
            
      ## add server to Server Group
      if [[ $OS_VERSION == "Red Hat ES 6."* ]]
        then
          echo "server is RHEL6"
		  blcli_execute ServerGroup groupNameToId $PARENT_GROUP/$RHEL6_GROUP
		  blcli_storeenv SERVER_GROUP_ID
          blcli_execute StaticServerGroup addServerToServerGroupByName $SERVER_GROUP_ID $arg
          # set exist flag to true, if false then Compliance job will not get executed.
		  RHEL6_SERVER_EXISTS='true'
      elif
        [[ $OS_VERSION == "Red Hat ES 5."* ]]
        then
          echo "server is RHEL5"
		  blcli_execute ServerGroup groupNameToId $PARENT_GROUP/$RHEL5_GROUP
		  blcli_storeenv SERVER_GROUP_ID
          blcli_execute StaticServerGroup addServerToServerGroupByName $SERVER_GROUP_ID $arg
		  # set exist flag to true, if false then Compliance job will not get executed.
		  RHEL5_SERVER_EXISTS='true'
      elif
        [[ $OS_VENDOR == "SUN Microsystems" ]] && [[ $OS_VERSION == "10" ]]
        then
          echo "server is Solaris 10"
		  blcli_execute ServerGroup groupNameToId $PARENT_GROUP/$SOL10_GROUP
		  blcli_storeenv SERVER_GROUP_ID
          blcli_execute StaticServerGroup addServerToServerGroupByName $SERVER_GROUP_ID $arg
		  # set exist flag to true, if false then Compliance job will not get executed.
		  SOL10_SERVER_EXISTS='true'
      fi
         
            echo "-------------------------------------------"
    else
      echo "server '$arg' is not enrolled in BSA"
      echo "------------------------------------------"
  fi
  echo ""  
done

## Run Compliance - RHEL5
if [[ $RHEL5_SERVER_EXISTS == 'true' ]]
then
  blcli_execute BatchJob getDBKeyByGroupAndName "/Compliance" "ACTIVE RHEL5 TSS Compliance" 
  blcli_storeenv JOB_KEY
  blcli_execute Job executeAgainstServerGroups $JOB_KEY "$PARENT_GROUP/$RHEL5_GROUP"
fi	  

## Run Compliance - RHEL6
if [[ $RHEL6_SERVER_EXISTS == 'true' ]]
then
  blcli_execute BatchJob getDBKeyByGroupAndName "/Compliance" "ACTIVE RHEL6 TSS Compliance" 
  blcli_storeenv JOB_KEY
  blcli_execute Job executeAgainstServerGroups $JOB_KEY "$PARENT_GROUP/$RHEL6_GROUP"
fi

## Run Compliance - SOL10
if [[ $SOL10_SERVER_EXISTS == 'true' ]]
then
  blcli_execute BatchJob getDBKeyByGroupAndName "/Compliance" "ACTIVE SOLARIS TSS Compliance" 
  blcli_storeenv JOB_KEY
  blcli_execute Job executeAgainstServerGroups $JOB_KEY "$PARENT_GROUP/$SOL10_GROUP"
fi  

## Delete temporary server group
blcli_execute StaticServerGroup deleteGroupByQualifiedName $PARENT_GROUP/$RHEL5_GROUP
blcli_execute StaticServerGroup deleteGroupByQualifiedName $PARENT_GROUP/$RHEL6_GROUP
blcli_execute StaticServerGroup deleteGroupByQualifiedName $PARENT_GROUP/$SOL10_GROUP	  

blcli_disconnect