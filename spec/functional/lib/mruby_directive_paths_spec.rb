require 'spec_helper'
require 'jwt'
require 'rest-client'

describe 'mruby_directive_paths' do
  let(:expiration) { (Time.now + options.jwtap_expiration_duration_seconds.to_i - 1).to_i }
  let(:headers) { { Authorization: "Bearer #{jwt}" } }
  let(:jwt) { JWT.encode payload, secret_key, 'HS256' }
  let(:options) { OpenStruct.new(ENV.inject({}) { |h, (k, v)| h.tap { |h| h[k.downcase.to_sym] = v } }) }
  let(:payload) { { sub: 'mruby_directive_paths', exp: expiration } }
  let(:secret_key) { Base64.decode64 options.jwtap_secret_key_base64 }
  let(:url) do
    "http://#{options.nginx_server_name}:#{options.nginx_server_port}#{options.nginx_location_test_paths}"
  end

  subject { RestClient.get(url, headers) { |response, _request, _result| return response } }

  it 'executes scripts in order' do
    expect(JSON.parse(subject.headers[:x_mruby_directive_paths])).to include('sub' => 'mruby_directive_paths')
  end
end
