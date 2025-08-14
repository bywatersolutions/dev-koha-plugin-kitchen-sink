#!/bin/bash

if git log -1 --pretty=oneline | grep -v 'Version auto-incremented'
then
  if echo $TRAVIS_BRANCH | grep main
  then
    echo "Building release"
    node increment_version.js
    git commit -a -m "Version auto-incremented  - $TRAVIS_JOB_NUMBER [ci skip]"
    gulp build
    gulp release
    git remote add github https://$GITHUB_TOKEN@github.com/bywatersolutions/koha-plugin-kitchen-sink
    git fetch --all
    git push github HEAD:main
  fi
else
  echo "No release needing."
fi
