#!/usr/bin/env bash

export PUBLISH_BRANCH=${PUBLISH_BRANCH:-master}

# Signing Apps
if [ "$TRAVIS_BRANCH" == "$PUBLISH_BRANCH" ]; then
    echo "Push to master branch detected, signing the app..."
    cp ./app/build/outputs/apk/app-release-unsigned.apk ./app/build/outputs/apk/app-release-unaligned.apk
    jarsigner -verbose -tsa http://timestamp.comodoca.com/rfc3161 -sigalg SHA1withRSA -digestalg SHA1 -keystore scripts/key.jks -storepass $STORE_PASS -keypass $KEY_PASS ./app/build/outputs/apk/app-release-unaligned.apk $ALIAS
    ${ANDROID_HOME}/build-tools/25.0.3/zipalign -v -p 4 ./app/build/outputs/apk/app-release-unaligned.apk ./app/build/outputs/apk/app-release.apk

    # Publishing App
    echo "Publishing app to Play Store..."
    gem install fastlane
    fastlane supply --apk ./app/build/outputs/apk/app-release.apk --track alpha --json_key scripts/fastlane.json --package_name $PACKAGE_NAME
fi

# Create a new folder and copy the builded apk to there
mkdir $HOME/work_new
cp -rf ./app/build/outputs/apk/ $HOME/work_new

git config --global user.email "no-reply@travis-ci.org"
git config --global user.name "apt-bot"

# Clone the repo on apk branch after going to $HOME
cd $HOME
git clone --quiet --branch=apk https://apt-bot:$BOT_TOKEN@github.com/fossasia/loklak_wok_android  development > /dev/null

# Switch to the repository and checkout the branch
cd ./development
git checkout apk

# Clean up the branch and add the apk
rm -rf ./*
cp -rf $HOME/work_new/ ./
git add .

# Checking for staged changes
git status --porcelain|grep "M"
# if there are changes
if [ "$?" = 0 ]; then
  git commit --message "Apk update for build:$TRAVIS_BUILD_NUMBER | Generated by Travis CI --skip-ci"
  git remote add origin-pages https://apt-bot:$BOT_TOKEN@github.com/fossasia/loklak_wok_android.git
  git pull --rebase origin-pages apk
  git push --quiet --set-upstream origin-pages apk
  echo "Commit has been made, Happy coding :)"
else # NO Changes fallback...
  echo "No changes detected.... Not commiting... Happy coding :)"
fi
