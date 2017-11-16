#!/usr/bin/env bash
set -evx

# Clean
cd vendor
rm -fr ngx_mruby-*

# Decompress source
tar xzf ../rpmbuild/SOURCES/ngx_mruby-*.tar.gz

# Add gems
cd ngx_mruby-*
../../bin/add_gems.sh

# Work around Makefile build_mruby using git to revert changes to mruby/build_config.rb
git init
git add mruby/build_config.rb

# Build
nginx_config_opt_env="--prefix=$(pwd)/build/nginx --with-http_ssl_module"
if [ $(which brew) ]; then
  brew update
  brew install openssl
  openssl_path=$(brew --prefix openssl)
  cflags="-I${openssl_path}/include"

  NGINX_CONFIG_OPT_ENV="${nginx_config_opt_env} --with-cc-opt=${cflags}" \
    NGX_MRUBY_CFLAGS="${cflags}" \
    NGX_MRUBY_LDFLAGS="-L${openssl_path}/lib -lcrypto" \
    ./build.sh
else
  NGINX_CONFIG_OPT_ENV="${nginx_config_opt_env}" ./build.sh
fi

# Install
LDFLAGS="-lcrypto" make install
