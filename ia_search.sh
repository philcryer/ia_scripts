#!/bin/bash

EXPECTED_ARGS=1
if [ $# -ne $EXPECTED_ARGS ]; then
	echo "Usage: `basename $0` {arg}"
	exit 1
fi

curl -s -i --output search.txt -XPOST "http://www.archive.org/advancedsearch.php?q=${1}&fl${1}=identifier&sort${1}=&sort${1}=&sort${1}=&rows=50&indent=yes&fmt=json&xmlsearch=Search" 

URL=`grep Location: search.txt | cut -d" " -f2`; rm search.txt 

wget -q --output-document=result.txt ${URL}

grep title result.txt | tail -n1; grep source result.txt | tail -n1; grep identifier result.txt | tail -n1; grep description result.txt | tail -n1 | more

rm result.txt

exit 0
