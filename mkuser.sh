#!/bin/bash
# PATH=/Applications/MySQLWorkbench.app/Contents/MacOS;${PATH}
case "$OSTYPE" in
  solaris*) echo "SOLARIS" ;;
  darwin*)  PATH=/Applications/MySQLWorkbench.app/Contents/MacOS:/usr/bin:${PATH}
    export LC_CTYPE=C
  ;;
  linux*)   echo "LINUX" ;;
  bsd*)     echo "BSD" ;;
  msys*)    echo "WINDOWS" ;;
  cygwin*)  echo "ALSO WINDOWS" ;;
  *)        echo "unknown: $OSTYPE" ;;
esac

# Function to generate a random password with a length of 12
generate_random_password() {
    #< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c"${1:-12}"
    tr -dc '_[:alnum:]' < /dev/urandom | head -c"${1:-12}"
    echo
}
# Attempt to help the executor, who should be executed if he is the author
clhelp () {
  cmd=$(basename $0)
  echo "Syntax $cmd" >&2
  echo "$cmd hostname newuser scriptfile {\$option} (script file may contain \$username, \$hostname \$option and it will be expanded before execution in mysql \$option being optional" >&2
  echo "$cmd hostname newuser database   (grants read only on database)" >&2
  echo >&2
  echo "It will spit out information at the end to paste into https://ots.ingramcontent.com/" >&2  
}

# MySQL connection details
hostname=$(echo $1 | tr -dc '[:alnum:].' | tr '[:upper:]' '[:lower:]')
if [[ -z $hostname ]]; then
  clhelp
  exit 1
fi
new_user=$(echo $2 | tr -dc '[:alnum:]_-' | tr '[:upper:]' '[:lower:]')
if [[ -z $new_user ]] ; then
  clhelp
  exit 2
fi
# Read the new username from the command line
#read -p "Enter the new username: " new_user

# Generate a random password for the new user
new_user_password=$(generate_random_password 12)

# Create a new MySQL user with the random password
create_user_query="CREATE USER $new_user@'%' IDENTIFIED BY '$new_user_password';"
create_user_output=$(mysql -h ${hostname} -e "$create_user_query" 2>/dev/null)
created=$?
if [ $created -ne 0 ]; then
   if [[ $create_user_output == *"ERROR 1396"* ]]; then
      new_user_password="Not Changed"
   else
      echo $create_user_output
      new_user_password="Not Changed"
   fi
fi

# Check if script name is provided as command-line argument
if [ $# -ge 3 ]; then
    # Execute the specified script file
    if [ -r $3 ]; then
       script_file=$3
       option=$4
       eval "echo \"$(<$script_file)\"" | mysql -h ${hostname}
    else
       echo "GRANT SELECT ON $3.* TO $new_user@'%';" | mysql -h ${hostname}
    fi
fi

    grant_user_output=$(echo "show grants for $new_user;" | mysql -h ${hostname})

# Print the hostname, username, and password
echo "Scriptname: $script_file"
echo "Hostname:   $hostname"
echo "Username:   $new_user"
echo "Password:   $new_user_password"
echo "Grants:     $grant_user_output"
