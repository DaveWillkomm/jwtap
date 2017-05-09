Nginx::Request.new.var.mruby_directive_paths.split.each { |path| load path }
