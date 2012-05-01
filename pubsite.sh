#!/bin/sh

HOST=ssh-staff.rice.edu

echo "Starting to sftp ..."

lftp -v -u wcm1 -e "mirror --reverse --delete --only-newer $HOME/publish Public/www" $HOST  

exit 0
