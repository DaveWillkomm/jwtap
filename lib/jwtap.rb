require File.expand_path('../jwtap/access_handler.rb', __FILE__)

Jwtap::AccessHandler.new(Nginx::Request.new).process
