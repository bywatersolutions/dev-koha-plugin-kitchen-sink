#!/bin/bash

if git log -1 --pretty=oneline | grep -v 'Version auto-incremented'
then
  echo "Building release"
  node increment_version.js
  git commit -a -m 'Version auto-incremented'
  gulp build
  gulp release
  git remote add github https://$GH_TOKEN@github.com/bywatersolutions/koha-plugin-kitchen-sink
  git push github HEAD:master
else
  echo "No release needing."
fi
