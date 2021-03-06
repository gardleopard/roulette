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
    result = settings.imagecollection.find queryjson
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
    result = settings.imagecollection.find queryjson
    @images = []
    result.each do | image |
      @images.push "/images/"+image['file'] 
    end

    mustache :result
  end

  
  get '/roulette' do 
    result = settings.imagecollection.find
    rnd1 = rand(result.count)
    rnd2 = rand(result.count)
    if rnd1 == rnd2 
      redirect '/roulette'
    end

    @image1 = result.to_a[rnd1]
    result = settings.imagecollection.find
    @image2 = result.to_a[rnd2]
    
    mustache :roulette   
  end
 
  get '/win/*' do 
    file = params[:splat].first
    pp file
    json = { :file => file }
    image = settings.imagecollection.find_one json
    if image
      image["wins"] = image["wins"] + 1
      settings.imagecollection.update({"_id" => image["_id"]}, image)
    end
    redirect '/roulette'
  end

  post '/upload' do
    tempfile  = params['file'][:tempfile]
    filename  = params['file'][:filename]
  
    time = Time.new
    path="./public/images/uploads/#{time.year}/#{time.month}/#{time.day}"
    imagepath="/images/uploads/#{time.year}/#{time.month}/#{time.day}"
    received_image =  {
      "file" => "uploads/#{time.year}/#{time.month}/#{time.day}/#{filename}",
      "type" => "image"
    }
    
    image = settings.imagecollection.find_one received_image
    if image
      "Image exist"
    else
      if ! File.directory? path 
        FileUtils.mkdir_p(path)
      end  
      FileUtils.cp tempfile.path, "#{path}/#{filename}"
      received_image.merge! :wins => 0
      received_image.merge! "exif" => get_exif("#{path}/#{filename}")

      settings.imagecollection.insert(received_image)
      @imageurl = "#{imagepath}/#{filename}"
      mustache :upload
    end
  end
   configure do
    set :connection, Mongo::Connection.new
    set :db, connection["roulette"]
    set :imagecollection, db["images"]
  end
  
  def get_exif(filename)
      exif = MiniExiftool.new "#{filename}"
      exif_data = {}

      exif.to_hash.each do |key,value|
        exif_data.merge! key => value.to_s
      end
      exif_data
    
  end

end  
