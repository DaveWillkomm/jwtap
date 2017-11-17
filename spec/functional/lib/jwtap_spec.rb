require 'spec_helper'
require 'ostruct'

describe 'jwtap' do
  let(:nginx_url) { "https://#{options.nginx_server_name}:#{options.nginx_server_port}" }
  let(:options) { OpenStruct.new(ENV.inject({}) { |h, (k, v)| h.tap { |h| h[k.downcase.to_sym] = v } }) }

  context 'given an API proxy' do
    let(:url) { "#{nginx_url}#{options.nginx_location_test_api}" }

    it_behaves_like 'a proxied location', :api
  end

  context 'given an application proxy' do
    let(:url) { "#{nginx_url}#{options.nginx_location_test_application}" }

    it_behaves_like 'a proxied location', :application
  end
end
