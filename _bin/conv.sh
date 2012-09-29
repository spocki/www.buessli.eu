#!/bin/bash
cd $(dirname $0)
cd ../europareise2012
for file in $(ls *.md) ; do
   echo ${file}
#   sed -e "s/<%= site.picasa.alben\[/#{site.buessli.album(/g" ${file} | sed -e "s/\].get_picture_table %>/)}/g" > "${file}.txt"
#   mv "${file}.txt" "${file}"
#   sed -e "s/<p class=\"where\">//g" ${file} > "${file}.txt"
#   mv "${file}.txt" "${file}"

#   sed -e "s/<div class=\"map\" gpx=\"<%= @site.base_url %>\/gpx\//#{site.buessli.map(\"/g" ${file}  > "${file}.txt"
#   mv "${file}.txt" "${file}"

   sed -e "s/.gpx\"><\/div>/\", true)}/g" ${file}  > "${file}.txt"
   mv "${file}.txt" "${file}"


#   sed -e "s/<img src='\/posts/<img src='<%= @site.base_url %>\/posts/g" ${file} > "${file}.txt"
#   mv "${file}.txt" "${file}"

#   sed -e "s/\"\/gpx\//\"<%= @site.base_url %>\/gpx\//g" ${file} > "${file}.txt"
#   mv "${file}.txt" "${file}"
done