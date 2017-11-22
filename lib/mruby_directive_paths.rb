#TODO deleteme
var = Nginx::Var.new
h = {
  host: var.host,
  scheme: var.scheme,
  server_name: var.server_name,
  server_port: var.server_port
}
Nginx.errlogger Nginx::LOG_ERR, "\n\n=== #{h} ================================================================================\n\n "

Nginx::Request.new.var.mruby_directive_paths.split.each { |path| load path }
