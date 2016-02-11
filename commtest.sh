#!/bin/bash
# This script takes in a CSV file with hostnames, does 3 tests (resolve,ping,port) on each
# hostname, then outputs a CSV file with test results for each hostname
# Run this on any Linux OS that has getent, ping, and nmap installed
# usage > ./commtest.sh hostnamesfile.csv



FILE=$1
PORT=4750

OUTFILE="commtest_result.csv"

if [ ! -f $OUTFILE ]
then 
	touch $OUTFILE
fi


function write_output {
echo "$1,$2,$3,$4"$'\r' >> $OUTFILE
}


## create header row
echo "hostname,name_resolution,ping,port 4750"$'\r' > $OUTFILE

cat $FILE | while read line;
do
	TARGET=`echo $line | awk -F',' '{print $1}'`
	if [ ! $line == "" ]
	then
		
		## -----------   HOSTNAME RESOLVE TEST

		IPADDR=`getent hosts $TARGET | wc -l`

		if [ $IPADDR = 1 ];
		then
			RESOLVE="pass"
		else 
			RESOLVE="fail"
			write_output $TARGET $RESOLVE - - -
			continue 2
		fi


	

		## -----------   PING TEST

		count=$( timeout 3 ping -c 1 $TARGET | grep icmp* | wc -l )

		if [ $count -eq 0 ]
		then
    			PINGTEST="fail"
			write_output $TARGET $RESOLVE  $PINGTEST - -
			continue 2
		else
    			PINGTEST="pass"
		fi






		## ------------- NMAP 4750 TEST

		open=`nmap -p $PORT $TARGET | grep "$PORT" | grep open`
		if [ -z "$open" ]; 
		then
			TESTPORT="fail"
			write_output $TARGET $RESOLVE $PINGTEST $TESTPORT -
 			continue 2
		else
 			TESTPORT="pass"
		fi

		write_output $TARGET $RESOLVE $PINGTEST $TESTPORT

	fi

done


