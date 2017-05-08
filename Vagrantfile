# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'centos/7'

  config.vm.define 'build', primary: true do |build|
    build.vm.provision 'shell', path: 'bin/build/provision.sh'

    # I was unable to successfully change the default synced folder's provider to vboxsf for bi-directional syncing, so
    # I disabled it and configured a separate folder.
    build.vm.synced_folder '.', '/vagrant', disabled: true
    build.vm.synced_folder '.', '/home/vagrant/jwtap', provider: :vboxsf
  end

  config.vm.define 'test', autostart: false do |test|
    test.vm.provision 'shell', path: 'bin/test/provision.sh'
    test.vm.synced_folder '.', '/vagrant', disabled: true
  end
end
