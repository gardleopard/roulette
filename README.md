#Set up developer environment
* sudo apt-get install mongodb libimage-exiftool-perl ruby-full
* install rubygems
* install bundler
* bundle install
* bundle exec shotgun config.ru


#Add images to the app
* find . -name *.JPG -exec curl -F file=$PWD/{} http://localhost:9292/register \;
* cd public 
* mkdir images
* cd images
* ln -s /dir/with/images
