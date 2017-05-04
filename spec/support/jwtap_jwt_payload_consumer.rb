request = Nginx::Request.new
request.headers_out['X-mruby-directive-paths'] = request.var.jwtap_jwt_payload
