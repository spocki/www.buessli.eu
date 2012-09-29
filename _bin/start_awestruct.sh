#!/bin/bash
cd $(dirname $0)
cd ..
_bin/remove_tmp.sh 
rm -rf _site 
awestruct -d
