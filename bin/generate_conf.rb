#!/usr/bin/env ruby
require 'erb'

jwtap_jwt_payload_consumer_path = File.expand_path '../spec/support/jwtap_jwt_payload_consumer.rb', __dir__
jwtap_path = File.expand_path '../lib/jwtap.rb', __dir__
mruby_directive_paths_path = File.expand_path '../lib/mruby_directive_paths.rb', __dir__

ssl_cert_path = File.expand_path '../nginx/ssl/domain.crt', __dir__
ssl_key_path = File.expand_path '../nginx/ssl/domain.key', __dir__

path = File.expand_path '../nginx/conf/nginx.conf.erb', __dir__
source = File.read path
erb = ERB.new source
destination_path = File.expand_path '../nginx/conf/nginx.conf', __dir__
File.write destination_path, erb.result
