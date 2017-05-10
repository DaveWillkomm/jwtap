#!/usr/bin/env bash
if [[ ! ${1} ]]; then
  echo "Version required, e.g. 1.1.0"
  exit 0
fi

set -evx
vagrant up test
vagrant scp rpmbuild/RPMS/**/jwtap-${1}-*.rpm test:~/
vagrant ssh test -c "sudo yum -y install jwtap-${1}-*.rpm"
