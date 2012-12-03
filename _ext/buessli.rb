require 'rexml/document'
require 'fileutils'
require 'date'
require 'json'
require 'uri'

module Awestruct
  module Extensions
    class Buessli
      
      def initialize
      end
      
      def execute(site)
        site.buessli = BuessliHelper.new(site)
      end
    end
  end
end

class BuessliHelper
  def initialize(site)
    @site = site
    
    input_all_file = "./_gpx/json/track-zusammenfassung.small.json"
    body = ""
    file = File.new( input_all_file , "r")
    while (line = file.gets)
      body += line
    end
    file.close
    @json_tracks = JSON.parse(body)
    
    input_all_file = "./_gpx/json/track-zusammenfassung.publish.small.json"
    body = ""
    file = File.new( input_all_file , "r")
    while (line = file.gets)
      body += line
    end
    file.close
    @json_publish_tracks = JSON.parse(body)
    
    input_all_file = "./_gpx/json/track-zusammenfassung.latest.small.json"
    body = ""
    file = File.new( input_all_file , "r")
    while (line = file.gets)
      body += line
    end
    file.close
    @json_latest_track = JSON.parse(body)
    
  end
  
  # this has to be generic!
  def route_json
    html = "  window.buessli.route = true;\n"
    for json_track in @json_publish_tracks do
      html += "  window.buessli.gpxtracks.push(" + json_track.to_json + ");\n"
    end
    return html
  end
  
  def map(gpx="", profile=false)
    html = "<p>"
    json_track_to_insert = {}
    found = false; 
    for json_track in @json_tracks do
      if (gpx == json_track["name"])
        json_track_to_insert = json_track
        found = true;
      end
    end
    if (gpx == "zusammenfassung.small.position")
      json_track_to_insert = @json_latest_track
      found = true;
    end
    if (!found)
      # puts gpx + " not found!"
    end
    id = ((rand() * 1000) + 1000).round().to_s
    if (@site.online)
      html += "<center>" 
      html += "<script language=\"javascript\">"
      html += "  window.buessli.gpxtracks.push(" + json_track_to_insert.to_json + ")"
      html += "</script>"
      html += "<table class=\"map\" gpx=\""
      html += @site.base_url
      html += "/gpx/"
      html += gpx
      html += ".gpx"
      html += "\">\n"
      html += "<tr>" 
      html += "<td>" 
      html += "<div class=\"map\" id=\"MAP" + id + "\">"
      html += "</div>"
      html += "</td>" 
      html += "</tr>" 
      if (profile) 
        html += "<tr>" 
        html += "<td>" 
        html += "<div class=\"map_profile\" id=\"PROFIL" + id + "\">\n"
        html += "</div>"
        html += "</td>" 
        html += "</tr>" 
      end
      html += "</table>" 
      html += "</center>" 
    else
      html += "<div class=\"map\">"
      html += "<img src=\"" + @site.base_url + "/images/map.png\">\n"
      html += "</div>"
    end 
    html += "</p>"
    return html
  end
  
  def album(album="", cell_one=1, cell_two=2, cell_three=3, cell_four=4)
    html = ""
    picasa_album_to_insert = @site.picasa.alben[album]
    if picasa_album_to_insert != nil
      html += "<script language=\"javascript\">"
      html += "  window.buessli.picasa.push(" + picasa_album_to_insert.to_json + ")"
      html += "</script>"
      html += picasa_album_to_insert.get_picture_table(cell_one, cell_two, cell_three, cell_four)
    else
      html += "ALBUM:  " + album + " nicht gefunden!"
    end
    return html
  end
  
  def panoramas
    panoramas = @site.picasa.alben["panorama_4x1"].pictures.reverse
    new_panoramas = []
    new_panoramas << panoramas[0]
    new_panoramas << panoramas[1]
    new_panoramas << panoramas[2]
    new_panoramas << panoramas[3]
    new_panoramas << panoramas[4]
    counter = 5
    while ( new_panoramas.length < 20 )
      new_panoramas << panoramas[counter]
      counter += 3
    end
    return new_panoramas
  end
  
  def youtube(videoId="")
    html = "<object width='763' height='480'>"
    html += "<param name='movie' value='https://www.youtube.com/v/" + videoId + "?version=3&autoplay=0&theme=light&modestbranding=1'/>"
    html += "<param name='allowFullScreen' value='true'/>"
    html += "<param name='allowScriptAccess' value='always'/>"
    html += "<embed allowscriptaccess='always' width='763' src='https://www.youtube.com/v/" + videoId + "?version=3&autoplay=0&theme=light&modestbranding=1' allowfullscreen='true' type='application/x-shockwave-flash' height='480'/>"
    html += "</object>"
    return html;
  end
  
  def header(content="")
    if ( content.length > 850 )
      t1 = content.index("<", 600)
      t2 = content.index(" ", 850)
      if (t1 < t2)
        t2 = t1
      end
      value = content[0,t2]
      index = value.index("<script")
      if (index)
        value = value[0,index]
      end
      index = value.index("<table")
      if (index)
        value = value[0,index]
      end
      return value
    end
    return content
  end
  
  def google_translate(lang="en", page="")
    picture = @site.base_url + "/images/flag-" + lang + "-s.png"
    url = @site.base_url + page.url
    url = url.gsub(/:/, "%3A")
    url = url.gsub(/\//, "%2F")
    #out = "http://translate.google.de/translate?hl=de&sl=de&tl=" + lang + "&u=" + url
    out = "<a class=\"top\" data-translation-lang=\"" + lang + "\" data-url=\"" + url + "\"><img src=\"" + picture + "\"></a>"
    return out
  end
  
  def blog_as_json
    html = "window.buessli.blog = "
    html += @site.blogasjson["pages"].to_json
    html += ";\n"
    return html
  end
  
  def picasa_as_json
    html = ""
    for name in @site.picasa.names do
      album = @site.picasa.alben[name].dup
      album.link = album.link.gsub(/https:\/\/picasaweb.google.com\// , "")
      album.pictures = album.pictures[0,6] 
      for picture in album.pictures do
        picture["link"] = picture["link"].gsub(/https:\/\/picasaweb.google.com\// , "")
      end
      html += "window.buessli.picasa.push("
      html += album.to_json
      html += ");\n"
    end
    return html
  end
  
  def route_popups
    html = "<div class=\"hidden\">"
    for name in @site.picasa.names do
      if name.match(/^20.*/) 
        stamp1 = name[0,10]
        date1 = Date.parse(stamp1,"%Y-%m-%d")
        date2 = date1 + 1
        date3 = date1 + 2
        stamp2 = date2.strftime("%Y-%m-%d")
        stamp3 = date3.strftime("%Y-%m-%d")
        # puts stamp1 + " " + stamp2 + " " + stamp3
        html += "<div data-popup-name=\"" + stamp1 + "\">"
        for page in @site.blogasjson["pages"] do
          if stamp1 == page.date
            html += "<a href=\""+ page.url + "\">" + page.title + "</a><br>"
          end
          if stamp2 == page.date
            html += "<a href=\""+ page.url + "\">" + page.title + "</a><br>"
          end
          if stamp3 == page.date
            html += "<a href=\""+ page.url + "\">" + page.title + "</a><br>"
          end
        end
        album = @site.picasa.alben[name]
        for picture in album.pictures[0,6] do
          html += "<a href=\"" + picture["link"] + "\">"
          html += "<img data-lazy-src=\"" + picture["url"].gsub(/\/s220-c\//,"/s60-c/") + "\">"
          html += "</a>&nbsp;"
        end
        html += "</div>"
      end
    end
    html += "</div>"
    return html
  end
  
  def panorama(image="")
    html = ""
    if image != ""
      # puts "PANO: #{image}"
      panorama_album = @site.picasa.alben["panorama_4x1"]
      for picture in panorama_album.pictures
        url = picture["url"].gsub(/\.wm\./, ".")
        # puts "URL : #{url}" 
        if url.match(image)
          html = "<table>\n"
          html += "<tr>\n"
          html += "<td>\n"
          html += "<a href=\"" + picture["link"] + "\">"
          html += "<img class=\"panorama\" src=\""
          url = picture["url"]
          html += url
          html += "\" />"
          html += "</a\n"
          html += "</td>\n"
          html += "</tr>\n"
          html += "</table>\n"
          break
        end
      end
    end
    return html
  end
  
end
