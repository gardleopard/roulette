require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'mustache/sinatra'
require 'fileutils'
require 'neo4j'
require 'pp'
include Neo4j

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

get '/roulette/:champion/:challenger' do | champion, challenger | 
  @champion   =  "/img/#{champion}"
  @challenger =  "/img/#{challenger}"
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


class Image
    include Neo4j::NodeMixin
    property :filename

    has_n :better
    has_n :worse
    index :filename
end


post '/upload' do
  tempfile = params['file'][:tempfile]
  filename = params['file'][:filename]
  FileUtils.cp tempfile.path, "./uploads/#{filename}"
  
  Neo4j::Transaction.run do
    node = Image.new(:filename => filename)
  end
  redirect "/preview/#{filename}"
end

get '/search/:key' do | key | 
  image = Image.find("filename: #{key}").first
  redirect "/preview/#{image.filename}"
end












































#https://github.com/andreasronge/neo4j

