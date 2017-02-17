#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install puppet
sudo gem install librarian-puppet
librarian-puppet install
sudo puppet apply --modulepath=modules manifests/site.pp
