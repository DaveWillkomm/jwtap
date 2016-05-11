require 'base64'
require 'cgi'
require 'jwt'
require 'rest-client'

shared_examples 'a proxied location' do |proxy_type|
  let(:algorithm) { options[:jwtap_algorithm] }
  let(:authorization_header) { { Authorization: "#{authorization_schema}#{jwt}" } }
  let(:authorization_schema) { 'Bearer ' }
  let(:cookie_header) { { Cookie: "#{cookie_name}=#{jwt}" } }
  let(:cookie_name) { options[:jwtap_cookie_name] }
  let(:default_next_url) { options[:jwtap_default_next_url] }
  let(:expiration) { (Time.now + options[:jwtap_expiration_duration_seconds].to_i - 1).to_i }
  let(:headers) { {} }
  let(:jwt) { JWT.encode payload, secret_key, algorithm }
  let(:login_url) { options[:jwtap_login_url] }
  let(:payload) { { sub: 'test-subject', exp: expiration } }
  let(:secret_key) { Base64.decode64 options[:jwtap_secret_key_base64] }

  context 'given no JWT' do
    it_behaves_like 'an unauthenticated request', proxy_type, :no_jwt
  end

  context 'given a JWT authorization header' do
    let(:headers) { authorization_header }

    it_behaves_like 'an authenticated request', :bearer
    it_behaves_like 'unauthenticated requests', proxy_type

    context 'given no bearer schema' do
      let(:authorization_schema) { nil }

      it_behaves_like 'an unauthenticated request', proxy_type, :no_jwt
    end
  end

  context 'given a JWT cookie' do
    let(:headers) { cookie_header }

    it_behaves_like 'an authenticated request', :cookie
    it_behaves_like 'unauthenticated requests', proxy_type

    context 'given an invalid cookie name' do
      let(:cookie_name) { "not-the-#{options[:jwtap_cookie_name]}" }

      it_behaves_like 'an unauthenticated request', proxy_type, :no_jwt
    end
  end
end

shared_examples 'unauthenticated requests' do |proxy_type|
  context 'given an expired JWT' do
    let(:expiration) { (Time.now - 60).to_i }

    it_behaves_like 'an unauthenticated request', proxy_type
  end

  context 'given a JWT without an expiration' do
    let(:payload) { { sub: 'test-subject' } }

    it_behaves_like 'an unauthenticated request', proxy_type
  end

  context 'given an invalid JWT' do
    let(:secret_key) { "not-the-#{options[:jwtap_secret_key]}" }

    it_behaves_like 'an unauthenticated request', proxy_type
  end
end

shared_examples 'an authenticated request' do |jwt_location|
  it 'proxies the request' do
    RestClient.get url, headers do |response, _request, _result|
      jwt = if jwt_location == :bearer
        response.headers[:authorization_jwt_refreshed]
      else
        response.cookies[cookie_name]
      end
      payload, _header = JWT.decode jwt, secret_key, true, algorithm: algorithm

      expect(response.code).to eq(200)
      expect(payload['sub']).to eq('test-subject')
      expect(payload['exp'].to_i).to be > expiration
    end
  end
end

shared_examples 'an unauthenticated request' do |proxy_type, jwt = :has_jwt|
  if proxy_type == :application
    it 'redirects to the login URL' do
      RestClient.get url, headers do |response, _request, _result|
        expect(response.code).to eq(302)
        expect(response.headers[:location]).to eq("#{login_url}#{CGI.escape url}")
      end
    end

    context 'given an unsafe HTTP method (i.e. non-GET)' do
      it 'redirects to the login URL with a next URL of the configured default' do
        RestClient.delete url, headers do |response, _request, _result|
          expect(response.code).to eq(302)
          expect(response.headers[:location]).to eq("#{login_url}#{CGI.escape default_next_url}")
        end
      end

      context 'given a referrer' do
        let(:referrer) { 'https://example.com/test-application/model/uuid'}

        it 'redirects to the login URL with a next URL of the referrer' do
          headers.merge! Referer: referrer

          RestClient.delete url, headers do |response, _request, _result|
            expect(response.code).to eq(302)
            expect(response.headers[:location]).to eq("#{login_url}#{CGI.escape referrer}")
          end
        end
      end
    end
  elsif jwt == :has_jwt
    it 'returns a 401 with a WWW-Authenticate header including an invalid_token error code and login URL' do
      RestClient.get url, headers do |response, _request, _result|
        expect(response.code).to eq(401)
        expect(response.headers[:www_authenticate]).to eq(%Q(Bearer error="invalid_token", login_url="#{login_url}"))
      end
    end
  else
    it 'returns a 401 with a WWW-Authenticate header including a login URL' do
      RestClient.get url, headers do |response, _request, _result|
        expect(response.code).to eq(401)
        expect(response.headers[:www_authenticate]).to eq(%Q(Bearer login_url="#{login_url}"))
      end
    end
  end
end
