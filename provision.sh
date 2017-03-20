#!/usr/bin/env bash
cd ${0%/*}

sudo apt-get update
sudo apt-get install -y puppet
sudo gem install librarian-puppet
librarian-puppet install
sudo puppet apply --modulepath=modules manifests/site.pp
