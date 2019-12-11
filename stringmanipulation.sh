#!/bin/bash

# I wrote and use this script to maintain a reverse tunnel via ngrok.

# this script demonstrates usage of the following tools
# - Jenkins - to run the script periodically
# - bash - this script
# - pidof - check for a running process
# - ngrok - to create and manage a tunnel
# - jq - parse the json returned by the ngrok api
# - grep and awk - figure out the new location details
# - PHP - a simple redirect to the new location
# - SCP - and ssh keys to upload
# - Apache - to erve the PHP redirect file
# - AWS - to host the web page


# check if ngrok is running/not
pidof  ngrok >/dev/null
if [[ $? -ne 0 ]] ; then
		# A (re)start and update is required
		echo "Starting ngrok on $(date)"
		# Start up a new instance of ngrok
		BUILD_ID=dontKillMe nohup /root/ngrok/ngrok http -region eu 80 &
		# Give it a moment before testing it...
		echo "Sleeping for 15 seconds..."
		sleep 15
		# Get the updated publish_url value from the ngrok api
		export NGROKURL=`curl -s http://127.0.0.1:4040/api/tunnels | jq '.' | grep public_url | grep https | awk -F\" '{print $4}'`
		echo "NGROKURL is $NGROKURL"
		# add that to a one-line PHP redirect page
		echo "<?php header('Location: $NGROKURL/zm'); exit;?>" > zm.php
		# upload that to my AWS host
		echo "scp'ing zm.php to AWS host..."
		scp -i /MY_AWS_KEY_FILE.pem zm.php MY_AWS_USER@MY_AWS_HOST.amazonaws.com:/MY_HTDOCS_DIR/ZoneMinder.php
		echo "Transfer complete."
		# Send an update message via email
		echo "New ngrok url is $NGROKURL/zm" | mailx -s "ngrok zm url updated" MY_EMAIL@gmail.com
else
		# Nothing needed, carry on
		echo "ngrok is currently running, nothing to do"
fi
