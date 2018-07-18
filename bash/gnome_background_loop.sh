#!/bin/bash

# 1. location of wallpapers
# 2. get number of files in location
# 2. random sort and get random nr
# 3. pick random file
# 4. set background

setBackground () {
	`gsettings set org.gnome.desktop.background picture-uri file://$1`
}

# pass directory with background as first argument
WORKDIR=$1
cd $WORKDIR
for f in $(ls | sort -R | tail -1)
do
	BACKGROUND="$WORKDIR""$f"
	setBackground $BACKGROUND

done
