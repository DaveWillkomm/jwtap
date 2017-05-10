#!/usr/bin/env bash
set -evx

curl -L https://centos7.iuscommunity.org/ius-release.rpm > /tmp/ius-release.rpm
set +e
yum -y install /tmp/ius-release.rpm
set -e
yum -y install \
  tmux \
  tree
