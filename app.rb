require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'mustache/sinatra'
require 'fileutils'
#require 'neo4j'
require 'pp'
require 'mongo'
require 'json'
#include Neo4j


class RouletteService 
  Sinatra.register Mustache::Sinatra

  require 'views/layout'
  
  set :mustache, {
    :views     => 'views/',
    :templates => 'templates/'
  }
  
 
  
  get '/' do
    mustache :index
  end
  
  get '/hello/:name' do | name |
    @name = name
    mustache :hello
  end
  
  
  get '/upload' do
    mustache :upload
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
     
     
     send_file("./uploads/#{filename}")
  end
  
  
  #class Image
  #    include Neo4j::NodeMixin
  #    property :filename
  
  #    has_n :better
  #    has_n :worse
  #    index :filename
  #end
  
  
  post '/upload' do
    tempfile  = params['file'][:tempfile]
    filename  = params['file'][:filename]
    imagename = params['imagename']  
  
    received_image = {
      :imagename => imagename,
      :filename  => filename,
      :type      => "image"
    }
    image = options.imagecollection.find_one received_image
    if image
      "Image exist"
    else
      FileUtils.cp tempfile.path, "./uploads/#{filename}"
      received_image.merge! :wins => 0
      options.imagecollection.insert(received_image)
      redirect "/preview/#{filename}"
    end
    
  
    
  
  #  Neo4j::Transaction.run do
  #    node = Image.new(:filename => filename)
  #  end
    
  end
  
  post 'winner/:imageid' do | imageid |
    
  end
  
  #get '/search/:key' do | key | 
  #  image = Image.find("filename: #{key}").first
  #  redirect "/preview/#{image.filename}"
  #end
   
  get '/mongodb' do
  
       #imagejson = imagecollection.find({:type => "image"}).to_a #.to_a.first
       imagejson = imagecollection.find.to_a #.to_a.first
       pp_debug imagejson
  #     pp_debug imagecollection.methods.sort
  #     imagecollection.drop  
     #pp_debug imagejson["filename"]
  #     pp_debug imagecollection.size     
       #parsed = JSON.parse(imagejson)
       #pp_debug parsed 
  
  end

  helpers do 
    def pp_debug(obj)
      "<pre>#{obj.pretty_inspect}</pre>"
    end
  
    configure do
      set :connection, Mongo::Connection.new
      set :db, connection.db("roulette")
      set :imagecollection, db.collection("images")
    end
  end
end  








































#https://github.com/andreasronge/neo4j

