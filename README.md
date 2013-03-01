#Set up developer environment
* sudo apt-get install mongodb libimage-exiftool-perl ruby-full
* install rubygems
* install bundler
* bundle install
* bundle exec shotgun config.ru


#Add images to the app
* find . -name "*.jpg" -exec curl -i -F imagename={} -F file=@{} http://localhost:9393/upload \;
