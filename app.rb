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
      @images.push "/image"+image['file'] 
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
 
  get '/win/*' do 
    file = params[:splat].first
    pp file
    json = { :file => file }
    image = options.imagecollection.find_one json
    if image
      image["wins"] = image["wins"] + 1
      options.imagecollection.update({"_id" => image["_id"]}, image)
    end
    redirect '/roulette'
  end

  post '/register' do
    file = params['file'].sub("\/\.\/","\/")
      exif = MiniExiftool.new "#{file}"
      received_image =  {}
      exif_data = {}

      exif.to_hash.each do |key,value|
        exif_data.merge! key => value.to_s
      end
      received_image.merge! "wins" => 0
      received_image.merge! "exif" => exif_data
      received_image.merge! "file"  => file
      received_image.merge! "type"  => "image"
      options.imagecollection.insert(received_image)
  end
  

  post '/upload' do
    tempfile  = params['file'][:tempfile]
    filename  = params['file'][:filename]
  
    time = Time.new
    path="./public/images/uploads/#{time.year}/#{time.month}/#{time.day}"
    imagepath="/images/uploads/#{time.year}/#{time.month}/#{time.day}"
    received_image = {
      :file => "uploads/#{time.year}/#{time.month}/#{time.day}/#{filename}",
      :type      => "image"
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
