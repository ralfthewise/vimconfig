#!/bin/bash

git submodule init
git submodule update

#build command-t
echo 'Building command-t.  Make sure you are building it against the version of ruby vim was built with (vim --version)...'
cd submodules/command-t/ruby/command-t
make clean
rm Makefile
ruby extconf.rb
make
cd ../../../..

#check for needed commands
command -v coffee >/dev/null 2>&1 || echo >&2 'coffee is not installed'
command -v coffeelint >/dev/null 2>&1 || echo >&2 'coffeelint is not installed'
