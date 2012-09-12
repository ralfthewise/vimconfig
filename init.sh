#!/bin/bash

git submodule init
git submodule update

#build command-t
echo 'Building command-t.  Make sure you are building it against the version of ruby vim was built with (vim --version)...'
cd submodules/command-t/ruby/command-t
ruby extconf.rb
make
cd ../../../..
