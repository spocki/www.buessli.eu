#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'fileutils'
require 'uri'
require 'net/http'
require 'net/https'

here = File.expand_path(File.dirname(__FILE__))

root = File.join(here, '..')
json_dir = File.join(root, '_gpx/json')

for json_file in Dir[json_dir + "/track-2012*.json"]
  body = ""
  file = File.new( json_file , "r")
  while (line = file.gets)
    body += line
  end
  file.close
  track = JSON.parse(body)
  name = track["name"]
  last_point = track["points"][-1] 
  lon = last_point["lon"]
  lat = last_point["lat"]
  # puts name + ": " + lon + " / " + lat
  url = "http://maps.googleapis.com/maps/api/geocode/json?address=" + lat + "," + lon + "&sensor=false"
  url = URI.parse( url )
  # puts url
  http = Net::HTTP.new(url.host, url.port)
  request = Net::HTTP::Get.new(url.request_uri)
  res = http.start {|http| http.request(request) }
  body = JSON.parse(res.body)
  puts name[0,10] + " : " + body["results"][0]["formatted_address"]
  sleep 1
end
