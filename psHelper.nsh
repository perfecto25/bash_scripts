#!/bin/nsh
#Statics
BLFS=127.0.0.1
SENSORS_DIR=/opt/bmc/fileserver/extended_objects
 
#Input Vars
SENSORS_SCRIPT=$1
VCENTERUSER=$2
VCENTERPW=$3
TARGET=$4
DIR=$5

#[ $# -ne 5 ] && echo "Check input variables" && exit 1
 
#As a first step we have to verify if PowerShell exists on the target
nexec $TARGET c:\\Windows\\system32\\reg query "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\PowerShell"  > NUL 2>&1
 
# If PowerShell does not exist we post a stament about it in XML format. Then we exit with "0" to make sure things like compliance don't fail du to "Asset Collection" errors
if [ $? -ne 0 ] ; then
        echo "Powershell not found"
        exit 0
fi

 
# If PS is found we copy the sensors script to our target server
cp //$BLFS/$SENSORS_DIR/$SENSORS_SCRIPT //$TARGET/$DIR/$SENSORS_SCRIPT
 
# Change directory to the target
cd //$TARGET/$DIR
 
# Now execute the script and redirect the Error-Output to NUL
# The mode setting is required as nexec otherwise truncates output
nexec -i -e cmd /c "mode 1000,50 &&  echo . | c:\\windows\\system32\\WindowsPowerShell\\v1.0\\powershell.exe ./$SENSORS_SCRIPT $VCENTERUSER $VCENTERPW" 2>NUL

 
#[ $? -ne 0 ] && echo "failed, Powershell Script exited with a Non-Zero ExitCode"
 
# Finally delete the script and exit with 0
#rm $SENSORS_SCRIPT
#exit 0
