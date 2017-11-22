module Jwtap
  class AccessHandler
    JWT_ALGORITHM = 'HS256'

    def initialize(request)
      @request = request
    end

    def process
      if jwt
        begin
          secret_key = Base64.decode @request.var.jwtap_secret_key_base64
          payload, _header = JWT.decode jwt, secret_key, true, algorithm: JWT_ALGORITHM
          fail_request unless payload['exp']
          refreshed_jwt = refresh payload, secret_key
          @request.var.set 'jwtap_jwt_payload', JSON.generate(payload) if @request.var.jwtap_jwt_payload

          if bearer
            @request.headers_out['Authorization-JWT-Refreshed'] = refreshed_jwt
          elsif cookie
            @request.headers_out['Set-Cookie'] =
              "#{cookie_name}=#{refreshed_jwt}; Domain=#{@request.var.jwtap_cookie_domain}; Path=/; Secure;"
          end
        rescue JWT::DecodeError, JWT::ExpiredSignature => e
          Nginx.log Nginx::LOG_DEBUG, e
          fail_request
        end
      else
        fail_request false
      end
    end

    private

    def bearer
      authorization = @request.headers_in['Authorization']
      if authorization
        match = /^Bearer (\S+)$/.match authorization
        bearer = match[1] if match
      end

      bearer
    end

    def cookie
      cookies[cookie_name] if cookies
    end

    def cookie_name
      @request.var.jwtap_cookie_name || 'jwt'
    end

    def cookies
      Hash[@request.var.http_cookie.split('; ').map { |s| s.split('=', 2) }] if @request.var.http_cookie
    end

    def expiration_duration_seconds
      @request.var.jwtap_expiration_duration_seconds || 1800
    end

    def fail_request(invalid_token = true)
      if @request.var.jwtap_proxy_type == 'application'
        Nginx.redirect login_url
      else
        error = invalid_token ? 'error="invalid_token", ' : nil
        @request.headers_out['WWW-Authenticate'] = %Q(Bearer #{error}login_url="#{@request.var.jwtap_login_url}")
        Nginx.return  Nginx::HTTP_UNAUTHORIZED
      end
    end

    def jwt
      bearer || cookie
    end

    def login_url
      "#{@request.var.jwtap_login_url}#{HTTP::URL::encode(next_url)}"
    end

    def next_url
      port = %w(80 443).include?(@request.var.server_port) ? nil : ":#{@request.var.server_port}"
      next_url = if @request.var.request_method == 'GET'
        "#{@request.var.scheme}://#{@request.var.host}#{port}#{@request.var.request_uri}"
      else
        @request.var.http_referer || @request.var.jwtap_default_next_url
      end

      next_url
    end

    def refresh(payload, secret_key)
      refreshed_expiration = (Time.now + expiration_duration_seconds.to_i).to_i
      refreshed_payload = payload.merge 'exp' => refreshed_expiration
      JWT.encode refreshed_payload, secret_key, JWT_ALGORITHM
    end
  end
end
