#!/bin/bash
APP_NAME=$1
PROCFILE=$2
CONFIG=$3
BUILDPACK=$4
DEFAULT_BUILDPACK="https://github.com/kr/heroku-buildpack-go"

function pathcombine {
	if [[ "$1" == *\\ ]]
	then
	    echo $1$2
	else
	    echo $1"/"$2
	fi	
}

function output {
	echo "----> "$1
}
function output_usage {
	echo '----------------------------------------'
	echo 'Heroku deployment tool'
	echo ' '
	echo 'This tool should be called from app directory.'
	echo '(i.e. GOPATH/src/github.com/mbelousov/demoapp)'
	echo '----------------------------------------'
	echo 'Usage: '
	echo 'deploy.sh app_name [procfile] [config] [buildpack]'
	echo '  app_name  - heroku application name'
	echo '  procfile  - content of Procfile (optional, use "" to skip)'
	echo '  config - heroku settings (optional, use "" to skip)'
	echo '  buildpack - Heroku buildpack (optional)'
	echo '                (default: '$DEFAULT_BUILDPACK')'
	echo '----------------------------------------'
	echo 'Example:'
	echo 'deploy.sh demoapp "web: demoapp" "APP_SETTING=VALUE" "https://github.com/mbelousov/heroku-buildpack-go-revel"'
}
if [[ $APP_NAME == "help" ]]; then
	output_usage
	exit
fi

CWD=$(pwd)
GOSRC=$(cd $GOPATH/src/ && pwd)
if [[ ! $CWD == $GOSRC* ]]; then
	output 'Repository package is not in GOPATH!'
	output_usage
	exit
fi

# getting full package name

REPO=${CWD:${#GOSRC}+1:${#CWD}-${#GOSRC}-1}


if test -z "$REPO"; then
	output "Repository is not provided"
	output_usage
	exit
fi
if test -z "$APP_NAME"; then
	output "Heroku App name is empty"
	output_usage
	exit
fi


if test -z "$BUILDPACK"; then
	BUILDPACK=$DEFAULT_BUILDPACK
	output "Buildpack is not provided. Using the default buildpack.."
fi
output "Buildpack: "$BUILDPACK

REPO_NAME=$(echo ${REPO_URL##*/} | awk -F '.' '{ print $1 }')



output 'Checking for modifications..'
git init 
if [[ ! $? = 0 ]]; then
	exit
fi

if ! test -z "$(git status --porcelain)"; then
    output 'Repository is dirty. Please commit or discard your changes.'
    exit
fi



output 'Heroku initialization..'
heroku login
output 'Adding heroku remote..'
git remote rm heroku > /dev/null 2>&1
heroku git:remote -a $APP_NAME
if [[ ! $? = 0 ]]; then
	exit
fi

output 'Setting configurations..'
heroku config:set BUILDPACK_URL=$BUILDPACK $CONFIG > /dev/null
if [[ ! $? = 0 ]]; then
	exit
fi

output 'Creating Procfile..'
echo $PROCFILE > Procfile
output 'Getting dependencies..'
godep save ./...

echo $REPO > .godir

git add -A .
git commit -m "heroku procfile and dependencies"

output 'Pushing heroku remote..'
git push --force heroku master
if [[ ! $? = 0 ]]; then
	exit
fi


heroku ps

heroku open



output 'Removing Godeps..'
rm -rf $CWD/Godeps
output 'Removing .godir..'
rm -f $CWD/.godir
output 'Removing .Procfile..'
rm -f $CWD/Procfile

output 'Reseting to previous commit..'
git reset --hard HEAD~1 && git clean -fd
