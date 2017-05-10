#!/usr/bin/env bash
set -evx

vagrant ssh -c '${HOME}/jwtap/bin/build/buildrpm.sh'
