require  'app'
require 'rack/test'
require 'pp'


module MyHelpers
  def app
   Sinatra::Application
  end
end
RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.include MyHelpers
end
describe RouletteService do
  context "upload" do
    it "stores an image" do
      post '/upload', 'file' => Rack::Test::UploadedFile.new('spec/fixtures/testimage.jpg', 'image/jpg')
      Dir['uploads/*'].should include('uploads/testimage.jpg') 
    end
  end
end
