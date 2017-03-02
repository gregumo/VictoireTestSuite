#!/bin/bash

# This file is to help with running behat tests on circleCI. It's needed to:
#  - Handle circleCI's parallelization.
#  - Handle searching in multiple directories for feature files.

declare -a path

if [ $1 = "widget" ]; then
    path=Tests/Widget
    mkdir vendor/victoire/victoire/$path
    cp -r Tests/Features vendor/victoire/victoire/$path
    cd vendor/victoire/victoire/
else
    path=Tests/Features
fi

if [ -z "${RUN_NIGHTLY_BUILD}" ]; then
    if [ -z "$CIRCLE_NODE_INDEX" ]; then
      echo "No parrallelism found, setting defaults to run all tests."
      CIRCLE_NODE_TOTAL=1
      CIRCLE_NODE_INDEX=0
    fi

    echo "\$CIRCLE_NODE_TOTAL = $CIRCLE_NODE_TOTAL"
    echo "\$CIRCLE_NODE_INDEX = $CIRCLE_NODE_INDEX"

    error=0
    pwd=$(pwd)
    declare -a files
    declare -a params
    # Fetch all of the feature files for each parameter (directories)

    echo "Seaching $path for feature files..."
    if [ -d "$path" ]; then
      while read -r entry; do
        echo "-- found $entry"
        files=(${files[@]} "$entry")
        # Bash wizardry so we can update the array (otherwise it's a subprocess)
      done < <(find $path | grep "\.feature$")
    else
      # Fetch all the params to be passed later to behat
      # Quote named params to allow special chars inside
      # them. This allow us to use && || or any other
      # reserved operand inside params.
      if [[ $path == *"="* ]]
      then
        arrParam=(${param//=/ })
        param="${arrParam[0]}='${arrParam[1]}'"
      fi
      echo "Fetch param $path"
      params=(${params[@]} "$path")
    fi

    for i in "${!files[@]}"; do
        if [ $(($i % $CIRCLE_NODE_TOTAL)) -eq $CIRCLE_NODE_INDEX ]; then
          echo "Running ./vendor/bin/behat --format=pretty --out=std --format=junit --out=$CIRCLE_TEST_REPORTS/$i/junit --rerun="return.log" ${params} `pwd`/${files[$i]}"
          time ./vendor/bin/behat --format=pretty --out=std --format=junit --out=$CIRCLE_TEST_REPORTS/$i/junit ${params} `pwd`/${files[$i]}
        fi
        # Mark the entire script as a failure if any of the iterations fail.
        if [ ! $? -eq 0 ]
        then
          error=1
        fi
    done
    exit $error
fi