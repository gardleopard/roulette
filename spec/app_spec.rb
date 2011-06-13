require 'app'
require 'rack/test'
require 'pp'
require 'fileutils'


module MyHelpers
  def app
   Sinatra::Application
  end
  
end
RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include MyHelpers
  config.after {
    connection = Mongo::Connection.new
    connection.drop_database "roulette"
  }
end
describe RouletteService do
  context "upload" do
    it "stores an image" do
      post '/upload', 'file' => Rack::Test::UploadedFile.new('spec/fixtures/testimage.jpg', 'image/jpg'), 'imagename' => 'testimage'
      Dir['uploads/*'].should include('uploads/testimage.jpg') 
      FileUtils.rm( 'uploads/testimage.jpg' ) 
    end
  end
  
  context "win" do
    it "registers a victory on an image" do
      connection = Mongo::Connection.new
      db = connection.db("roulette")
      imagecollection = db.collection("images")

      post '/upload', 'file' => Rack::Test::UploadedFile.new('spec/fixtures/testimage.jpg', 'image/jpg'), 'imagename' => 'testimage'
      imagejson = imagecollection.find_one 
      filename = imagejson.fetch 'filename'
      wins = imagejson.fetch "wins"
      post "/win/#{filename}"
      imagejson = imagecollection.find_one
      imagejson["wins"].should eql(wins + 1)
    end  
  end

  helpers do
    configure do
      set :connection, Mongo::Connection.new
      set :db, connection.db("roulette")
      set :imagecollection, db.collection("images")
    end 
  end
end
