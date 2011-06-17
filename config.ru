require File.expand_path("../app", __FILE__)
use Rack::Static, :urls => ['/css', '/js', '/images', '/favicon.ico'], :root => 'public'

run RouletteService

