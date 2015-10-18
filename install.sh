#!/bin/bash

MYSQL_ROOT_PASSWORD=root

# TODO: ask for upgrade if already installed
# install for brew packages
function install_pkg {
    echo "-> Installing $1"
    brew install $1
}

# install brew or update brew
if test ! $(which brew) ; then
    echo "-> Installing brew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    echo "-> Found brew, updating"
    brew update
fi

# check if brew is ok
echo "-> Check brew installation"
brew doctor
if [[ $? != 0 ]] ; then
    echo "-> Something's wrong, check brew manually"
    exit 1
fi

# cleanup brew
echo "-> Removing old brew formulas, if any"
brew cleanup

# install mysql
install_pkg mysql
# configure mysql
echo "-> Setting mysql to run at boot"
ln -sfv /usr/local/opt/mysql/*.plist ~/Library/LaunchAgents
echo "-> Launching mysql"
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist
echo "-> Waiting for mysql to start"
until lsof -i:3306
do
    echo -n "."
done
echo "-> Setting mysql root password"
mysqladmin -u root password $MYSQL_ROOT_PASSWORD

# install mongodb
install_pkg mongodb
# configure mongodb
echo "-> Setting mongodb to run at boot"
ln -sfv /usr/local/opt/mongodb/*.plist ~/Library/LaunchAgents
echo "-> Launching mongodb"
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mongodb.plist

# install php
echo "-> Adding tap homebrew/php"
brew tap homebrew/php
echo "-> Adding tap homebrew/dupes"
brew tap homebrew/dupes
echo "-> Installing php with fpm"
install_pkg php56
echo "-> Installing php mongodb"
install_pkg homebrew/php/php56-mongo
echo "-> Installing php xdebug"
install_pkg homebrew/php/php56-xdebug
echo "-> Setting php to run at boot"
ln -sfv /usr/local/opt/php56/homebrew.mxcl.php56.plist ~/Library/LaunchAgents/
echo "-> Launching php"
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.php56.plist

# install nginx
echo "-> Installing nginx"
install_pkg nginx
echo "-> Creating new root dir for php-fpm at ~/Work"
mkdir -p ~/Work
echo "-> Adding php server to nginx"
echo "server {

    listen 7000;
    server_name localhost;
    root ~/Work;

    location ~ \.php($|/) {
        # try_files    \$uri = 404;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
    }
}" > /usr/local/etc/nginx/servers/php-project.conf
echo "-> Setting nginx to run at boot"
ln -sfv /usr/local/opt/nginx/*.plist ~/Library/LaunchAgents
echo "-> Launching nginx"
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.nginx.plist

# install brew cask
if ! brew info brew-cask &>/dev/null; then
    echo "Installing brew cask"
    brew install caskroom/cask/brew-cask
fi

echo "-> Ready to run :)"
exit 0
