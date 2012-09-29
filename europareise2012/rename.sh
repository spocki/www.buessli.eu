#!/bin/bash
for ORIGINAL in $(ls *.erb) ; do 
    NEW=$(echo $ORIGINAL | sed -e "s/.html.erb/.md/g")
    echo $ORIGINAL $NEW
done