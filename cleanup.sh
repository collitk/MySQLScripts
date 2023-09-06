#!/bin/bash

# MySQL server connection settings
MYSQL_HOST=${1:`hostname`}

# Iteration times
count=0
max_attempts=5

# Threshold time in seconds (1 minute)
THRESHOLD_SECONDS=60

while [ $count -lt $max_attempts ] ; do
   # Get the currently running processes from the information_sch
   running_processes=$(mysql -h"$MYSQL_HOST" -e "SELECT ID, TIME, USER, HOST, INFO FROM information_schema.PROCESSLIST WHERE STATE = 'executing' AND 'system user';")

   # Loop through the running processes and check their execution time
   while read -r process; do
       process_id=$(echo "$process" | awk '{print $1}')
       execution_time=$(echo "$process" | awk '{print $2}')
       user=$(echo "$process" | awk '{print $3}')
       host=$(echo "$process" | awk '{print $4}')
       info=$(echo "$process" | awk '{$1=$2=$3=$4=""; print $0}' | sed 's/^[ \t]*//')

       # Check if the query is not running from web server (will not keep any server without reverse lookup.)
       if [ "$host" != *"web"* ]]; then 
         echo "Killing non-web query with process_id: $process_id, user: $user, host: $host"
         # Kill the query using the process_id
         #mysql -h"$MYSQL_HOST" -e "KILL $process_id;"
         echo "kill $process_id"
      fi
      
       # Check if the query has been running for more than the threshold
       if [ "$execution_time" -gt "$THRESHOLD_SECONDS" ]; then
           echo "Killing long runningquery with process_id: $process_id, user: $user, host: $host"
           # Kill the query using the process_id
           #mysql -h"$MYSQL_HOST" -e "KILL $process_id;"
           echo "kill $process_id"
       fi
   done <<< "$running_processes"

   # Sleep for a few seconds before checking the processes again
   sleep 10
   count=$((count + 1))
done
