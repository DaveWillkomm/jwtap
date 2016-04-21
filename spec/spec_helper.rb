# Use Dotenv to load the environment when executing with IntelliJ.
if ENV['RM_INFO']
  require 'dotenv'
  Dotenv.load File.expand_path('../.env.test', __dir__)
end

require 'support/shared_examples'
