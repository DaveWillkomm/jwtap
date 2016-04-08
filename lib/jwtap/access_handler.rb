def bearer(request)
  authorization = request.headers_in['Authorization']
  if authorization
    match = /^Bearer (\S+)$/.match authorization
    bearer = match[1] if match
  end

  bearer
end

def cookie(var)
  cookies = cookies var
  cookie = cookies[var.jwtap_cookie_name] if cookies
  cookie
end

def cookies(var)
  Hash[var.http_cookie.split(';').map { |s| s.split('=').map(&:strip) }] if var.http_cookie
end

def decode(var, jwt)
  payload, _header = JWT.decode jwt, var.jwtap_secret_key, true, algorithm: var.jwtap_algorithm
  payload
end

def encode(var, payload)
  JWT.encode payload, var.jwtap_secret_key, var.jwtap_algorithm
end

def fail_request(var, request, invalidToken = true)
  if var.jwtap_proxy_type == 'application'
    Nginx.redirect login_url(var)
  else
    error = invalidToken ? 'error="invalid_token", ' : nil
    request.headers_out['WWW-Authenticate'] = %Q(Bearer #{error}login_url="#{var.jwtap_login_url}")
    Nginx.return  Nginx::HTTP_UNAUTHORIZED
  end
end

def login_url(var)
  "#{var.jwtap_login_url}#{next_url var}"
end

def next_url(var)
  port = %w(80 443).include?(var.server_port) ? '' : ":#{var.server_port}"
  next_url = if var.request_method == 'GET'
    "#{var.scheme}://#{var.host}#{port}#{var.request_uri}"
  else
    var.http_referer || var.jwtap_default_next_url
  end

  next_url
end

def process(var, request)
  bearer = bearer request
  cookie = cookie var
  jwt = bearer || cookie

  if jwt
    begin
      payload = decode var, jwt
      fail_request var, request unless payload['exp']
      refreshed_jwt = refresh var, payload

      if bearer
        request.headers_out['Authorization-JWT-Refreshed'] = refreshed_jwt
      elsif cookie
        request.headers_out['Set-Cookie'] =
          "#{var.jwtap_cookie_name}=#{refreshed_jwt}; Domain=#{var.jwtap_cookie_domain}; Path=/;"
      end
    rescue JWT::DecodeError, JWT::ExpiredSignature => e
      Nginx.errlogger Nginx::LOG_DEBUG, e
      fail_request var, request
    end
  else
    fail_request var, request, false
  end
end

def refresh(var, payload)
  refreshed_expiration = (Time.now + var.jwtap_expiration_duration_seconds.to_i).to_i
  refreshed_payload = payload.merge 'exp' => refreshed_expiration
  JWT.encode refreshed_payload, var.jwtap_secret_key, var.jwtap_algorithm
end

process Nginx::Var.new, Nginx::Request.new
