#!/bin/bash

function output {
	echo "----> "$1
}
function pathcombine {
	if [[ "$1" == *\\ ]]
	then
	    echo $1$2
	else
	    echo $1"/"$2
	fi	
}

REPO=$1
REPO_MODE=$2
APP_NAME=$3
PROCFILE=$4
CONFIG=$5
IGNORE=$6
BUILDPACK=$7
DEFAULT_BUILDPACK="https://github.com/kr/heroku-buildpack-go"
DEFAULT_REPO_MODE='remote'
echo ""

if test -z "$REPO_MODE"; then
	output 'Mode is not provided. Using default..'
	REPO_MODE=$DEFAULT_REPO_MODE
fi
if [[ $REPO_MODE != "remote" ]] && [[ $REPO_MODE != "local" ]] ; then
	output "Invalid repo mode. Using default.."
	REPO_MODE=$DEFAULT_REPO_MODE
fi
output 'Mode: '$REPO_MODE
if [[ $REPO_MODE == "local" ]]; then
	if test -z "$GOPATH"; then
		output "GOPATH is empty"
		exit
	fi
	REPO_URL=$(pathcombine $GOPATH src/$REPO)
else
	REPO_URL="https://"$REPO
fi
output 'Repository: '$REPO_URL
if test -z "$REPO"; then
	output "Repository is not provided"
	exit
fi
if test -z "$APP_NAME"; then
	output "Heroku App name is empty"
	exit
fi


if test -z "$BUILDPACK"; then
	BUILDPACK=$DEFAULT_BUILDPACK
	output "Buildpack is not provided. Using the default buildpack.."
fi
output "Buildpack: "$BUILDPACK

CURRENT=$(date +%s)
REPO_NAME=$(echo ${REPO_URL##*/} | awk -F '.' '{ print $1 }')
DEPLOY_DIR='.deploy'
REPO_PATH=$DEPLOY_DIR"/"$REPO_NAME

LOCAL_REPO=$(pathcombine $GOPATH src/$REPO)
if [ ! -d "$DEPLOY_DIR" ]; then
	mkdir "$DEPLOY_DIR"
fi

output 'Removing '$REPO_PATH'..'
rm -rf $REPO_PATH

if [ ! -d "$REPO_PATH" ]; then
	output 'Cloning into '$REPO_PATH'..'
	git clone $REPO_URL $REPO_PATH
	if [[ ! $? = 0 ]]; then
		exit
	fi
fi	

output 'Change dir to '$REPO_PATH
cd $REPO_PATH
output 'Fetching..'
git fetch origin
output 'Reseting to origin..'
git reset --hard origin/master && git clean -fd

output 'Pulling from origin..'
git pull --force origin master
if [[ ! $? = 0 ]]; then
	exit
fi

output 'Heroku initialization..'
heroku login
output 'Checking heroku remote..'
git remote show heroku > /dev/null 2>&1 #git ls-remote --exit-code heroku
if [[ ! $? = 0 ]]; then
	output 'Adding heroku remote..'
	heroku git:remote -a $APP_NAME
	if [[ ! $? = 0 ]]; then
		exit
	fi
fi
output 'Setting configurations..'
heroku config:set BUILDPACK_URL=$BUILDPACK $CONFIG

output 'Creating Procfile..'
echo $PROCFILE > Procfile
output 'Getting dependencies..'
godep save
if [[ ! $? = 0 ]]; then
	echo $REPO > .godir
fi

if ! test -z "$IGNORE"; then
	output 'Updating index..'
	printf "\n"$IGNORE"\n" >> .gitignore
	git rm -r --cached .
fi

git add -A .
git commit -m "heroku procfile and dependencies"

output 'Pushing heroku remote..'
git push --force heroku master
if [[ ! $? = 0 ]]; then
	exit
fi

#output 'Scaling..'
#heroku ps:scale web=1
heroku ps

heroku open


#cd '../../'
#output 'Removing '$REPO_PATH'..'
#rm -rf $REPO_PATH

