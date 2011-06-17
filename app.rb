require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'mustache/sinatra'
require 'fileutils'
require 'pp'
require 'mongo'
require 'json'
require 'mini_exiftool'


class RouletteService < Sinatra::Base
  register Mustache::Sinatra


  require File.expand_path('../views/layout', __FILE__)
  
  set :mustache, {
    :views     => File.expand_path("../views", __FILE__),
    :templates => File.expand_path("../templates", __FILE__)
  }
  
  get '/' do
     redirect '/roulette'
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
      @images.push image['path']+"/"+image['filename'] 
    end
    mustache :result
  end
  
  get '/slideshow' do
    queryjson = {
      :wins => {"$gt" => 0}
      }
    result = options.imagecollection.find queryjson
    @images = []
    result.each do | image |
      @images.push image['path']+"/"+image['filename'] 
      pp image['filename']
    end

    mustache :result
  end

  
  get '/roulette' do 
    result = options.imagecollection.find
    rnd1 = rand(result.count)
    rnd2 = rand(result.count)
    if rnd1 == rnd2 
      redirect '/roulette'
    end

    @image1 = result.to_a[rnd1]
    result = options.imagecollection.find
    @image2 = result.to_a[rnd2]
    
    mustache :roulette   
  end
 
  get '/win/:filename' do | filename |
    json = { :filename => filename }
    image = options.imagecollection.find_one json
    image["wins"] = image["wins"] + 1
    options.imagecollection.update({"_id" => image["_id"]}, image)
    redirect '/roulette'
  end

  post '/register' do
    received_image = {
      :file  => params['file'],
      :type      => "image",
    }
      received_image.merge! :wins => 0
      exif = MiniExiftool.new "#{params['file']}"
      if exif
        exif.tags.sort.each do | tag |
          received_image.merge! tag => exif[tag]
        end
      end

      options.imagecollection.insert(received_image)
  end
  

  post '/upload' do
    tempfile  = params['file'][:tempfile]
    filename  = params['file'][:filename]
    imagename = params['imagename']  
  
    time = Time.new
    path="./public/images/uploads/#{time.year}/#{time.month}/#{time.day}"
    imagepath="/images/uploads/#{time.year}/#{time.month}/#{time.day}"
    received_image = {
      :imagename => imagename,
      :filename  => filename,
      :filepath  => path,
      :type      => "image",
      :path      => imagepath
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
      @imageurl = "#{imagepath}/#{filename}"
      mustache :upload
    end
  end
   configure do
    set :connection, Mongo::Connection.new
    set :db, connection["roulette"]
    set :imagecollection, db["images"]
  end
end  
