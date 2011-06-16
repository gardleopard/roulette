require File.expand_path("../../app", __FILE__)
require 'rack/test'
require 'pp'
require 'fileutils'


module MyHelpers
  def app
    RouletteService
  end
end
RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include MyHelpers
  config.after {
    RouletteService.connection.drop_database('roulette')
    FileUtils.rm( "#{getpath}/testimage.jpg" )
  }
end
describe RouletteService do

  context "upload" do
    it "stores an image" do
      post '/upload', 'file' => Rack::Test::UploadedFile.new('spec/fixtures/testimage.jpg', 'image/jpg'), 'imagename' => 'testimage'
      Dir["#{getpath}/*"].should include("#{getpath}/testimage.jpg") 
    end
  end
 
  connection = Mongo::Connection.new
  db = connection["roulette"]
  imagecollection = db["images"]
 
  context "win" do
    it "registers a victory on an image" do
      post '/upload', 'file' => Rack::Test::UploadedFile.new('spec/fixtures/testimage.jpg', 'image/jpg'), 'imagename' => 'testimage'
      imagejson = imagecollection.find_one 
      filename = imagejson.fetch 'filename'
      wins = imagejson.fetch "wins"
      get "/win/#{filename}"
      imagejson = imagecollection.find_one
      imagejson["wins"].should eql(wins + 1)
    end  
  end
  def getpath 
    time = Time.new
    "./public/images/uploads/#{time.year}/#{time.month}/#{time.day}"
  end

end
