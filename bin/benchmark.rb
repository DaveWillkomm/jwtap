#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'base64'
require 'jwt'

application = ENV['TYPE'] == 'app'
concurrency = (ENV['CONCURRENCY'] || 100).to_i
expiration = (Time.now + ENV['JWTAP_EXPIRATION_DURATION_SECONDS'].to_i).to_i
header = application ? 'Cookie: jwt=' : 'Authorization: Bearer '
location = ENV[application ? 'NGINX_LOCATION_TEST_APPLICATION' : 'NGINX_LOCATION_TEST_API']
payload = { exp: expiration }
requests = (ENV['REQUESTS'] || 100 * concurrency).to_i
secret_key = Base64.decode64 ENV['JWTAP_SECRET_KEY_BASE64']
url = "http://#{ENV['NGINX_SERVER_NAME']}:#{ENV['NGINX_SERVER_PORT']}#{location}"
jwt = JWT.encode payload, secret_key, 'HS256'

command = %Q(ab -k -c #{concurrency} -n #{requests} -H "#{header}#{jwt}" #{url})
puts command
exec command
