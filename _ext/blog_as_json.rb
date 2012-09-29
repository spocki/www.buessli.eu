# -*- coding: undecided -*-
require 'date'
require 'json'

module Awestruct
  module Extensions
    class BlogAsJsonModule
      
      def initialize
      end
      
      def execute(site)
        puts "process BlogsAsJsonModule"
        puts "========================="
        
        site.blogasjson = {} 
        site.blogasjson["pages"] = []
        
        for page in site.pages do
          if ( page.output_path =~ /europareise2012\/2/ )
            json = {}
            json["url"] = site.base_url + page.output_path
            json["title"] = page.title
            if (page.date)
              json["date"] = page.date.strftime("%Y-%m-%d")
            end
            site.blogasjson["pages"].push(json)
          end
        end
      end
    end
  end
end