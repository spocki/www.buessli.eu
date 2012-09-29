# -*- coding: undecided -*-
require 'rexml/document'
require 'date'
require 'fileutils'
require 'net/http'
require 'net/https'
require 'uri'
require 'json'

module Awestruct
  module Extensions
    class Picasa
      
      def initialize(output_base_path='_picasa_cache/')
        @output_base_path = output_base_path
      end
      
      def execute(site)
        puts "Process Picasa"
        @site = site
        @site.picasa = {}
        @site.picasa.alben = {}
        @site.picasa.names = []
        rebuild_cache()
        @site.picasa.get_alben_overview = PicasaAlbumOverview.new(@site, @site.picasa.overview).get_overview_table

	write_json_files()
      end
      
      private
      
      def write_json_files
        output_file =  @output_base_path + "/picasa.json"
        # if ( ! File.exist?( output_file ) )
        FileUtils.mkdir_p( File.dirname( output_file ) )
        File.open( output_file, 'wb' ) do |f|
          f.write @site.picasa.to_json
        end
        # end
        # for album in @site.picasa.alben.keys do
        #   output_file =  @output_base_path + "/picasa-" + album + ".json"
        #   # if ( ! File.exist?( output_file ) )
        #   FileUtils.mkdir_p( File.dirname( output_file ) )
        #   File.open( output_file, 'wb' ) do |f|
        #     f.write @site.picasa.alben[album].to_json
        #   end
        #   # end
        # end
      end
      
      def rebuild_cache()
        handle_user("https://picasaweb.google.com/data/feed/base/user/115799352095294636731?alt=rss&hl=de&imgmax=100")
      end
      
      def handle_user(user_url)
        output_file = user_url.gsub(/https:\/\/picasaweb.google.com\/data\/feed\/base\//, @output_base_path)
        output_file = output_file.gsub(/\?.*/, "")
        output_file = output_file + ".xml"
        body = cache_file(user_url, output_file)
        doc = REXML::Document.new( body )
        root = doc.root
        
        @site.picasa.overview = PicasaAlbum.new(@site)
        @site.picasa.overview.pictures = []
        root.get_elements( 'channel/item' ).each do |item|
          @site.picasa.overview.pictures.push(handle_picture(item, "s220-c"))
        end
        
        root.get_elements( 'channel/item/guid' ).each do |item|
          handle_album(item.text) 
        end
      end
      
      def handle_album(album_url)
        album_url = album_url + "&kind=photo&imgmax=100"
        album_url = album_url.gsub(/\/entry\//, "/feed/")
        album_url = album_url.gsub(/\/photoid.*\?/, "?")
        output_file = album_url.gsub(/https:\/\/picasaweb.google.com\/data\/feed\/base\//, @output_base_path)
        output_file = output_file.gsub(/\?.*/, "")
        output_file = output_file + ".xml"
        body = cache_file(album_url, output_file)
        doc = REXML::Document.new( body )
        root = doc.root
        album_title = root.get_elements( 'channel/title' )[0].text
        pictures = []
        size = "s220-c"
        if ( album_title =~ /panorama/ )
          size = "s970"
        end
        root.get_elements( 'channel/item' ).each do |item|
          pictures.push(handle_picture(item, size))
        end
        @site.picasa.names.push(album_title)
        album = PicasaAlbum.new(@site, album_title)
        @site.picasa.alben[album_title] = album
        @site.picasa.alben[album_title].pictures = pictures
        @site.picasa.alben[album_title].link = root.get_elements("channel/link")[0].text
      end
      
      def handle_picture(picture_item, size)
        picture = {}
        url = picture_item.get_elements("media:group/media:content")[0].attributes["url"]
        pos = picture_item.get_elements("georss:where/gml:Point/gml:pos")
        url = url.gsub(/s100-c/, "s100")
        picture["url"] = url.gsub(/s100/, size)
        if (pos != nil && pos.length != 0)
          position = pos[0].text.split(' ') 
          picture["position"] = {}
          picture["position"]["lon"] = position[0]
          picture["position"]["lat"] = position[1]
        end
        picture["link"] = picture_item.get_elements("link")[0].text
        picture["title"] = picture_item.get_elements("title")[0].text
        return picture
      end
      
      def cache_file(url_to_get, output_file)
        body = "";
        if ( ! File.exist?( output_file ) )
          FileUtils.mkdir_p( File.dirname( output_file ) )
          body = get_url( url_to_get )
          File.open( output_file, 'wb' ) do |f|
            f.write body
          end
        else
          file = File.new( output_file , "r")
          while (line = file.gets)
            body += line
          end
          file.close
        end
        return body
      end
      
      def get_url(url_to_get)
        puts "GET " + url_to_get
        url = URI.parse( url_to_get )
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(url.request_uri)
        res = http.start {|http| http.request(request) }
        return res.body
      end
      
    end
    
  end
  
end

class PicasaAlbum
  
  attr :pictures, true
  attr :link, true
  attr :name, ""
  
  def initialize(site, name="default")
    @site = site
    @name = name
  end
  
  def get_picture_table(cell_one=1, cell_two=2, cell_three=3, cell_four=4)
    # puts "get picture table for " + @name
    html = "<table class=\"picasa_pictures\" data-title=\"" + @name + "\">\n"
    html += "<tr>\n"
    html += get_picture_cell(self.pictures[cell_one - 1 ])
    html += get_picture_cell(self.pictures[cell_two - 1])
    html += get_picture_cell(self.pictures[cell_three - 1])
    html += get_picture_cell(self.pictures[cell_four - 1])
    html += "</tr>\n"
    html += "</table>\n"
    html += "<p><center>\n"
    html += "<a class=\"top\" href=\"" + self.link + "\">\n"
    html += "[alle Bilder anzeigen]</a>\n"
    html += "</center></p>\n"
    return html
  end
  
  def get_picture_cell(picture)
    html = "<td>"
    if (picture != nil)
      # html += "<center>\n"
      # html += "<div class=\"picasa_picture\">\n"
      html += "<a class=\"top\" href=\"" + picture["link"] + "\">\n"
      url = picture["url"]
      if (!@site.online)
        url = @site.base_url + "/images/tmp.jpeg"
      end	
      html += "<img src=\"" + url + "\">\n"
      html += "</a>\n"
      # html += "</div>\n"
      # html += "</center>\n"
    end
    html += "</td>\n"
    return html
  end
  
  def to_json(*a)
    {
      'name'   => name,
      'link'   => link,
      'pictures'   => pictures
    }.to_json(*a)
  end
  
  def self.json_create(o)
    new(*o['data'])
  end
end

class PicasaAlbumOverview
  def initialize(site, album)
    @site = site
    @album = album
  end
  def get_overview_table
    html = "<table class=\"picasa_overview\" data-title=\"none\">\n"
    html += "<tr>\n"
    html += get_picture_cell(@album.pictures[0])
    html += get_picture_cell(@album.pictures[1])
    html += get_picture_cell(@album.pictures[2])
    html += get_picture_cell(@album.pictures[3])
    html += "</tr>\n"
    html += "<tr>\n"
    html += get_title_cell(@album.pictures[0])
    html += get_title_cell(@album.pictures[1])
    html += get_title_cell(@album.pictures[2])
    html += get_title_cell(@album.pictures[3])
    html += "</tr>\n"
    html += "<tr>\n"
    html += get_picture_cell(@album.pictures[4])
    html += get_picture_cell(@album.pictures[5])
    html += get_picture_cell(@album.pictures[6])
    html += get_picture_cell(@album.pictures[7])
    html += "</tr>\n"
    html += "<tr>\n"
    html += get_title_cell(@album.pictures[4])
    html += get_title_cell(@album.pictures[5])
    html += get_title_cell(@album.pictures[6])
    html += get_title_cell(@album.pictures[7])
    html += "</tr>\n"
    html += "</table>\n"
    return html
  end
  
  private
  
  def get_picture_cell(picture)
    html = "<td>\n"
    if (picture != nil)
      #html += "<center>\n"
      html += "<a class=\"top\" href=\"" + picture["link"] + "\">\n"
      url = picture["url"]
      if (!@site.online)
        url = @site.base_url + "/images/tmp.jpeg"
      end	
      html += "<img src=\"" + url + "\">\n"
      html += "</a>\n"
      #html += "</center>\n"
    end
    html += "</td>\n"
    return html
  end
  
  def get_title_cell(picture)
    html = "<td class=\"title\">\n"
    if (picture != nil)
      html += "<center>\n"
      html += "<a class=\"top\" href=\"" +  picture["link"] + "\">\n"
      html += picture["title"]
      html += "</a>\n"
      html += "</center>\n"
    end
    html += "</td>\n"
    return html
  end
end
