#!/bin/bash
#This script is intended to fix the common problem where npm users
#are required to use sudo to install global packages.
#It will backup a list of your installed packages
#remove all but npm, then create a local directory and
#configure node to use this for global installs
#whilst also fixing permissions on the .npm dir

file='/tmp/npm-reinstall.txt'

printf "\nSaving list of existing global npm packages\n"

#Get a list of global packages (not deps)
#except for the npm package
#save in a temporary file.
npm -g list -depth=0 | awk '!/npm/ {print $2}' >$file


printf "\nRemoving existing packages temporarily - you might need your sudo password\n\n"
#List the file
#replace the version numbers
#remove the newlines
#and pass to npm uninstall
cat $file | sed -e 's/@.*//' | xargs sudo npm -g uninstall

npmdir="${HOME}/npm"

printf "\nMake a new directory ${npmdir} for our "-g" packages\n"
mkdir -p ${npmdir}
npm config set prefix $npmdir

printf "\nFix permissions on the .npm directories\n"
me=`whoami`
sudo chown -R $me:$me ~/.npm

printf "\nReinstall packages\n"
#list the packages to install
#and pass to npm
cat $file | xargs npm -g install

bashfix='
NPM_PACKAGES="%s"
NODE_PATH="$NPM_PACKAGES/lib/node_modules:$NODE_PATH"
PATH="$NPM_PACKAGES/bin:$PATH"
# Unset manpath so we can inherit from /etc/manpath via the `manpath`
# command
unset MANPATH  # delete if you already modified MANPATH elsewhere in your config
MANPATH="$NPM_PACKAGES/share/man:$(manpath)"
'
printf "\n\n"
read -p "Do you wish to update your .bashrc file with the paths and manpaths? [yn] " yn
case $yn in
    [Yy]* ) printf "${bashfix}" ${npmdir} >> ~/.bashrc 
	    printf "\nDon't forget to run 'source ~/.bashrc'\n";;
    [Nn]* ) printf "\nYou may need to add the following to your ~/.bashrc / .zshrc file\n\n" 
	    	printf "${bashfix}\n\n" ${npmdir} ;;
    * ) echo "Please answer 'y' or 'n'.";;
esac

rm $file

printf "\nDone - packages are:\n\n"
npm -g list -depth=0
