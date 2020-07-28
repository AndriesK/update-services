# update-services

## How to

1. navigate to dir that contains all repos to be updated
2. run ./update-services.sh

## Notes

this script will keep a log of repos updated based in the dir you are running the script from.

By default, if a repo has been updated in the last 10 minutes, it is skipped. You can change the threshold in the script via the THRESHOLD var

## Uses

-f --force 
  ignore last updated check
-b --branch
  pull a specific branch from remote instead of master

## TODOS
add branch specific timers.
