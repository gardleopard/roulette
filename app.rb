require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'mustache/sinatra'
require 'fileutils'
require 'pp'
require 'mongo'
require 'json'
require 'mini_exiftool'


class RouletteService 
  Sinatra.register Mustache::Sinatra

  require 'views/layout'
  
  set :mustache, {
    :views     => 'views/',
    :templates => 'templates/'
  }
  
  get '/' do
    mustache :upload
  end
  
  get '/upload' do
    mustache :upload
  end
  
  get '/search/:key/:value' do | key, value | 
    queryjson = {
      key => value 
    }
    result = options.imagecollection.find queryjson
    @images = []
    result.each do | image |
      @images.push image['filename'] 
    end
    mustache :result
  end

  
  get '/roulette/:image1/:image2' do | image1, image2 | #soon deprecated 
    @image1   =  "/img/#{image2}"
    @image2 =  "/img/#{iamge2}"
    mustache :roulette
  end 

  get '/preview/:filename' do | filename |
    @imageurl = "/img/#{filename}"
    mustache :preview
  end
  
  get '/img/:filename' do | filename|
     content_type 'image/jpg'
     queryjson = {
      :filename => filename
     }
     image = options.imagecollection.find_one queryjson
     pp image
     path = image["path"]
     send_file("#{path}/#{filename}")
  end
  
  post '/win/:filename' do | filename |
    json = { :filename => filename }
    image = options.imagecollection.find_one json
    image["wins"] = image["wins"] + 1
    options.imagecollection.update({"_id" => image["_id"]}, image)
  end
  
  post '/upload' do
    tempfile  = params['file'][:tempfile]
    filename  = params['file'][:filename]
    imagename = params['imagename']  
  
    time = Time.new
    path="./uploads/#{time.year}/#{time.month}/#{time.day}"
    received_image = {
      :imagename => imagename,
      :filename  => filename,
      :type      => "image",
      :path      => path
    }
    
    image = options.imagecollection.find_one received_image
    if image
      "Image exist"
    else
      if ! File.directory? path 
        FileUtils.mkdir_p(path)
      end  
      FileUtils.cp tempfile.path, "#{path}/#{filename}"
      received_image.merge! :wins => 0
      exif = MiniExiftool.new "#{path}/#{filename}"
      if exif
        exif.tags.sort.each do | tag |
          received_image.merge! tag => exif[tag]
        end
      end 

      options.imagecollection.insert(received_image)
      redirect "/preview/#{filename}"
    end
  end
  
  helpers do 
    def pp_debug(obj)
      "<pre>#{obj.pretty_inspect}</pre>"
    end
  
    configure do
      set :connection, Mongo::Connection.new
      set :db, connection["roulette"]
      set :imagecollection, db["images"]
    end
  end
end  
