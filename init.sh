#!/bin/bash

git submodule init
git submodule update

#build command-t
cd submodules/command-t/ruby/command-t
ruby extconf.rb
make
cd ../../../..
