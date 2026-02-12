#!/bin/bash

# Just the git commit message title
title=$(git log -1 --pretty=%B | head -n 1)
git checkout master
# Save the messages into an array called message
IFS=$'\n' message=($(git log -1 --pretty=%B | sed -e '1,2d'))

if [[ $title = *"NOTIFY"* ]];
then
  formattedmessages=''
  for i in "${message[@]}"
  do
    formattedmessages=$formattedmessages'|'$i
  done

  curl -X POST -H "X-Admin-Password: $EMAILAUTHPASS" --data-urlencode "messages=$formattedmessages" "https://api.voiceit.io/platform/41"
fi
