#!/bin/bash
# Use this flag to accept all incoming changes from remote
# SPECIFIC_REPO=""

DONE_LOG="$(pwd)/.update-services-done-log.txt"

if [ ! -f $DONE_LOG ]; then
	touch "$(pwd)/.update-services-done-log.txt"
fi

CURRENT_DATE_UNIX_TIMESTAMP=$(date +%s)

# not using
DONE_DURATION="10 minutes"
# In seconds # 10 minutes
THRESHOLD=600

firstParam=$1

branch=master

should_force=false
updated=false
updateReturnCode=0
# Handle params passed
while [ "$1" != "" ]; do
    case $1 in
        -f | --force )          shift
                                should_force=true
                                ;;
	crm-service | product-master | product-master-interface | pricing-service | pricing-service-interface | pricing-engine | doc-gen | differentlife-batch)		shift
				SPECIFIC_REPO=$firstParam
				;;
	-b | --branch )		shift
				branch=$1
				;;
        * )                     usage
                                exit 1
    esac
    shift
done

gitoutput=""

for FILE in *; do
	if [ -d "$FILE" ] && [ -f $FILE/.git ]; then
		printf " -- Next repo: $FILE --\n\n"
		if [ $SPECIFIC_REPO ] && [ "$SPECIFIC_REPO" != "$FILE" ]; then
			echo "TEST: $SPECIFIC_REPO"
			continue
		fi
		cd "$FILE"
		REPO_TO_CHECK_AND_TIMESTAMP=$(cat $DONE_LOG | grep "${FILE}_.*")
		REPO_LAST_CHECK=${REPO_TO_CHECK_AND_TIMESTAMP/"${FILE}_"/}
		REPO_SHOULD_BE_CHECKED_AGAIN=$((REPO_LAST_CHECK + THRESHOLD))
		# If there is a last time checked to compare
		if [[ $REPO_LAST_CHECK ]]; then
			if [[ "$OSTYPE" == "darwin"* ]]; then
				echo "Last time checked: $(date -r ${REPO_LAST_CHECK})"
			else
				echo "Last time checked: $(date -d @${REPO_LAST_CHECK})"
			fi
			if [[ "$(date +%s)" > $REPO_SHOULD_BE_CHECKED_AGAIN ]] || [[ "$should_force" = true ]];
			then
				if [[ "$should_force" = true ]];
				then
					echo "--force used - forcing update.."
				else 
					echo "Last update exceeds threshold... updating: $FILE"
				fi
				gitoutput=$(git pull origin $branch 2>&1)
				updateReturnCode=$?
				if [ $updateReturnCode -eq 0 ]; then
					updated=true
					if [[ "$OSTYPE" == "darwin"* ]]; then
						gsed -i "/${FILE}_.*/d" $DONE_LOG
						if [ ! $? -eq 0 ]; then
							echo "please do brew install gnu-sed"
						fi
					else 
						sed -i "/${FILE}_.*/d" $DONE_LOG
					fi
					echo "${FILE}_$CURRENT_DATE_UNIX_TIMESTAMP" >> $DONE_LOG
				else
					updated=false
				fi
			else
				echo "Repo has been checked in past $THRESHOLD seconds.. to force add --force"
			fi
		else
			echo "Never checked, do update for: $FILE"
			gitoutput=$(git pull origin $branch 2>&1)
			updateReturnCode=$?
			if [ $updateReturnCode -eq 0 ]; then
				updated=true
				if [[ "$OSTYPE" == "darwin"* ]]; then
					gsed -i "/${FILE}_.*/d" $DONE_LOG
					if [ ! $? -eq 0 ]; then
						echo "please do brew install gnu-sed"
					fi
				else 
					sed -i "/${FILE}_.*/d" $DONE_LOG
				fi
				echo "${FILE}_$CURRENT_DATE_UNIX_TIMESTAMP" >> $DONE_LOG
			fi
		fi
		printf "$gitoutput\n"
		if [ $updateReturnCode -eq 0 ]; then
			echo "Result: $FILE updated: $updated"
		else
			if [[ $gitoutput =~ "find remote ref $branch" ]] 
			then
				echo "No branch "$branch" on remote..continuing"
			else
				echo "Update Services: Updated: $updated, Reason: Failed, please resolve any issues first and re-run this script."
				exit
			fi
		fi
		cd ..
		echo ""
	fi
done
