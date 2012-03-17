#!/bin/bash

if [ "x$1" = "x" ]
then
echo "An .m3u file is needed"
exit 1
fi

cat $1 | sed -e 's/\/music//' -e 's/\//\\/g' > $1-new
mv $1-new $1
crlf -v -d $1
