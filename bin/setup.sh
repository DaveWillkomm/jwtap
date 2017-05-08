#!/usr/bin/env bash
set -evx

brew tap caskroom/cask
brew cask install vagrant virtualbox
set +e
vagrant box add --provider virtualbox centos/7
set -e
vagrant plugin install \
  vagrant-scp \
  vagrant-vbguest
vagrant up
