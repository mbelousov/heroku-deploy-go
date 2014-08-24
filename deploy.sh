#!/bin/bash
REPO_URL=$1
APP_NAME=$2
PROCFILE=$3
CONFIG=$4
IGNORE=$5


if test -z "$REPO_URL"; then
	echo "Repository URL is empty"
	exit
fi
if test -z "$APP_NAME"; then
	echo "Heroku App name is empty"
	exit
fi

CURRENT=$(date +%s)
REPO_NAME=$(echo ${REPO_URL##*/} | awk -F '.' '{ print $1 }')
REPO_PATH='.deploy/'$REPO_NAME

if [ ! -d "$REPO_PATH" ]; then
	echo 'Cloning into '$REPO_PATH'..'
	git clone $REPO_URL $REPO_PATH
	if [[ ! $? = 0 ]]; then
		exit
	fi
fi

echo 'Change dir to '$REPO_PATH
cd $REPO_PATH
echo 'Fetching..'
git fetch origin
echo 'Reseting to origin..'
git reset --hard origin/master && git clean -fd

echo 'Pulling from origin..'
git pull --force origin master
if [[ ! $? = 0 ]]; then
	exit
fi

echo 'Heroku initialization..'
heroku login
echo 'Checking heroku remote..'
git remote show heroku #git ls-remote --exit-code heroku
if [[ ! $? = 0 ]]; then
	echo 'Adding heroku remote..'
	heroku git:remote -a $APP_NAME
	if [[ ! $? = 0 ]]; then
		exit
	fi
fi
echo 'Setting configurations..'
heroku config:set BUILDPACK_URL=https://github.com/kr/heroku-buildpack-go.git $CONFIG

#echo 'Checking heroku remote..'
#git show-ref --verify --quiet refs/remotes/heroku/master
#if [[ $? = 0 ]]; then
#	echo 'Pulling heroku remote..'
#	git pull heroku master
#	if [[ ! $? = 0 ]]; then
#		exit
#	fi
#fi

echo 'Creating Procfile..'
echo $PROCFILE > Procfile
echo 'Getting dependencies..'
godep save
if [[ ! $? = 0 ]]; then
	exit
fi

if ! test -z "$IGNORE"; then
	echo 'Updating index..'
	printf "\n"$IGNORE"\n" >> .gitignore
	git rm -r --cached .
fi

git add -A .
git commit -m "heroku procfile and dependencies"

echo 'Pushing heroku remote..'
git push --force heroku master
if [[ ! $? = 0 ]]; then
	exit
fi

#echo 'Scaling..'
#heroku ps:scale web=1
heroku ps

heroku open


#cd '../../'
#echo 'Removing '$REPO_PATH'..'
#rm -rf $REPO_PATH

