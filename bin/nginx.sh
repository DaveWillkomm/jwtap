#!/usr/bin/env bash
set -evx

vendor/ngx_mruby-*/build/nginx/sbin/nginx -p nginx "$@"
