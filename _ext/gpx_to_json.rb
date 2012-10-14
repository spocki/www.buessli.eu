#!/usr/bin/ruby

require 'rexml/document'
require 'fileutils'
require 'json'
require 'uri'


module Awestruct
  module Extensions
    class GpxToJsonModule
      
      def initialize
      end
      
      def execute(site)
        puts "process GpxToJsonModule"
        puts "======================="
        gpx_to_json = GpxToJson.new
        gpx_to_json.gpx_to_json
        gpx_to_json.concat_json_files
        gpx_to_json.simplify_concatination
      end
    end
  end
end

class GpxToJson
  def initialize(base_path="./_gpx", output_path="./_gpx")
    @base_path = base_path
    @output_path = output_path + "/json"
  end
  
  def simplify_concatination
    puts "simplify_concatination"
    input_all_file = @output_path + "/track-zusammenfassung.small.json"
    
    body = ""
    file = File.new( input_all_file , "r")
    while (line = file.gets)
      body += line
    end
    file.close
    
    json_tracks = JSON.parse(body)
    
    json_tracks = json_tracks.sort! { |a,b| a["name"].downcase <=> b["name"].downcase }
    
    json_latest_point = {}
    for json_track in json_tracks do
      for json_point in json_track["points"] do
        json_latest_point = json_point
      end
    end
    
    output_all_file = @output_path + "/track-zusammenfassung.latest.small.json"
    json_latest_track = {}
    json_latest_track["name"] = "zusammenfassung.latest.small"
    json_latest_track["points"] = []
    json_latest_track["points"] << json_latest_point
    FileUtils.mkdir_p( File.dirname( output_all_file ) )
    File.open( output_all_file, 'wb' ) do |f|
      f.write json_latest_track.to_json
    end
    
    for json_track in json_tracks do
      points = json_track["points"]
      mod = points.length / 50
      if (mod == 0)
        mod = 1
      end
      counter = 0
      new_points = []
      while counter < points.length do
        new_points << points[counter]
        counter += mod
      end
      json_track["points"] = new_points
    end
    
    output_all_file = @output_path + "/track-zusammenfassung.publish.small.json"
    FileUtils.mkdir_p( File.dirname( output_all_file ) )
    File.open( output_all_file, 'wb' ) do |f|
      f.write json_tracks.to_json
    end
  end
  
  def concat_json_files
    puts "concat_json_files"
    json_files = Dir.glob(@output_path + "/*2012*.json") 
    json_tracks = []
    for json_file in json_files do
      body = ""
      file = File.new( json_file , "r")
      while (line = file.gets)
        body += line
      end
      file.close
      json_track = JSON.parse(body)
      json_tracks << json_track
    end
    output_all_file = @output_path + "/track-zusammenfassung.small.json"
    FileUtils.mkdir_p( File.dirname( output_all_file ) )
    File.open( output_all_file, 'wb' ) do |f|
      f.write json_tracks.to_json
    end
  end
  
  def gpx_to_json
    puts "gpx_to_json"
    gpx_files = Dir.glob(@base_path + "/*2012*.gpx") 
    for gpx_file in gpx_files do
      if ( gpx_file =~ /.*2012.*/)
        json_file = @output_path + "/" + File.basename(gpx_file).gsub(/\.gpx/, ".json").gsub(/2012/, "track-2012") 
        if ( ! File.exist?( json_file ))
          puts gpx_file + " -> " + json_file
          body = ""
          file = File.new( gpx_file , "r")
          while (line = file.gets)
            body += line
          end
          file.close
          doc = REXML::Document.new( body )
          root = doc.root
          root.get_elements( 'trk' ).each do |trk|
            name = trk.get_elements( 'name' )[0].text
            # puts name
            json_track = {}
            json_track["name"] = name
            json_track["points"] = []
            trk.get_elements( 'trkseg/trkpt' ).each do |trkpt|
              ele = 0;
	      if (trkpt.get_elements( 'ele' )[0])
	        ele = trkpt.get_elements( 'ele' )[0].text
	      end
              lon = trkpt.attributes["lon"]
              lat = trkpt.attributes["lat"]
              #  puts lon + " " + lat + " " + ele
              json_point = {}
              json_point["lon"] = lon
              json_point["lat"] = lat
              json_point["ele"] = ele
              json_track["points"] << json_point
            end
            output_file = json_file
            FileUtils.mkdir_p( File.dirname( output_file ) )
            File.open( output_file, 'wb' ) do |f|
              f.write json_track.to_json
            end
          end
        end
      end
    end
  end
end
