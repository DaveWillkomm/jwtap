#!/usr/bin/env bash
sed -i.bak "s/^end$/  conf.gem :github => 'iij\/mruby-require'\\
  conf.gem :github => 'mattn\/mruby-base64'\\
  conf.gem :github => 'mattn\/mruby-http'\\
  conf.gem :github => 'prevs-io\/mruby-jwt'\\
end/" build_config.rb
