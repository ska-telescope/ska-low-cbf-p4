#!/bin/bash

TMPFILE=$HOME/tmp.txt
echo "tzdata tzdata/Areas select Australia" > $TMPFILE
echo "tzdata tzdata/Zones/Australia select Sydney" >> $TMPFILE
debconf-set-selections $TMPFILE
rm /etc/localtime
rm /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
rm $TMPFILE
