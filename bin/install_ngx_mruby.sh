#!/usr/bin/env bash
set -evx

if [[ $(which brew) ]]; then
  brew_prefix_openssl="$(brew --prefix openssl)"
fi

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

# Set config options (these are optional so that the Homebrew formula can specify different values)
if [[ -z ${NGINX_CONFIG_OPT_ENV} ]]; then
  NGINX_CONFIG_OPT_ENV="--prefix=$(pwd)/build/nginx --with-http_ssl_module"

  if [[ -n ${brew_prefix_openssl} ]]; then
    NGINX_CONFIG_OPT_ENV+=" --with-cc-opt=-I${brew_prefix_openssl}/include"
  fi
fi
if [[ -z ${NGX_MRUBY_CFLAGS} && -n ${brew_prefix_openssl} ]]; then
  NGX_MRUBY_CFLAGS="-I${brew_prefix_openssl}/include"
fi
if [[ -z ${NGX_MRUBY_LDFLAGS} ]]; then
  NGX_MRUBY_LDFLAGS='-lcrypto'

  if [[ -n ${brew_prefix_openssl} ]]; then
    NGX_MRUBY_LDFLAGS+=" -L${brew_prefix_openssl}/lib"
  fi
fi

# Build
NGINX_CONFIG_OPT_ENV="${NGINX_CONFIG_OPT_ENV}" \
  NGX_MRUBY_CFLAGS="${NGX_MRUBY_CFLAGS}" \
  NGX_MRUBY_LDFLAGS="${NGX_MRUBY_LDFLAGS}" \
  ./build.sh

# Install
LDFLAGS="-lcrypto" make install
