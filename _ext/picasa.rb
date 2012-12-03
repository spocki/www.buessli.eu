require 'rexml/document'
require 'date'
require 'fileutils'
require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'httparty'

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
        #convert
        process_alben
        create_overview
      end
      
      private
      
      def convert
        alben = []
        xml = REXML::Document.new(File.read('_picasa_cache/user/115799352095294636731.xml')).root
        for item in xml.get_elements( 'channel/item' )
          album = {}
          album["src"] = item.get_elements("guid")[0].text
          album["name"] = item.get_elements("title")[0].text
          alben << album
        end
        puts alben.to_json
      end
      
      def create_overview
        @site.picasa.overview = PicasaAlbum.new(@site)
        @site.picasa.overview.pictures = []
        for name in @site.picasa.names
          for picture in @site.picasa.alben[name].pictures
            if picture["tags"].include?("highlight")
              picture["title"] = name
              @site.picasa.overview.pictures << picture
            end
          end
        end
        @site.picasa.get_alben_overview = PicasaAlbumOverview.new(@site, @site.picasa.overview).get_overview_table
      end
      
      def process_alben
        puts "process_alben"
        config = JSON.parse(File.read('_config/alben.json'))
        
        for album in config
          name = album["name"]
          album_file_name = "_picasa_cache/#{name}.json"
          if File.exist?(album_file_name)
            # puts "LOAD: #{album_file_name}" 
            album = JSON.parse(File.read(album_file_name))
          else
            album["pictures"] = []
            puts "GET : #{name}"
            xml = REXML::Document.new(HTTParty.get(album["src"])).root
            for item in xml.get_elements( 'channel/item' )
              picture = {}
              url = item.get_elements("media:group/media:content")[0].attributes["url"]
              url = url.gsub(/s1500-c/, "s100")
              url = url.gsub(/s1500/, "s220-c")
              picture["url"] = url
              pos = item.get_elements("georss:where/gml:Point/gml:pos")
              if (pos != nil && pos.length != 0)
                position = pos[0].text.split(' ') 
                picture["position"] = {}
                picture["position"]["lon"] = position[0]
                picture["position"]["lat"] = position[1]
              end
              keywords = item.get_elements("media:group/media:keywords")[0]
              picture["tags"] = []
              if (keywords != nil)
                if (keywords.text != nil)
                  for keyword in keywords.text.split(',')
                    keyword.strip!
                    picture["tags"] << keyword
                  end
                end
              end
              picture["link"] = item.get_elements("link")[0].text
              picture["title"] = item.get_elements("title")[0].text
              album["pictures"] << picture
            end
            file = File.new(album_file_name, "w")
            file.write(JSON.pretty_generate(album))
            file.close
          end
          
          @site.picasa.names.push(name)
          @site.picasa.alben[name] = PicasaAlbum.new(@site, name)
          @site.picasa.alben[name].pictures = album["pictures"]
          @site.picasa.alben[name].link = album["src"]
          
        end
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
