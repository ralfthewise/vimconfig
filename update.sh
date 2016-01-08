#!/bin/bash

# this could probably be replaced with just:
#   git submodule update --remote --merge

ROOT="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${ROOT}"

for m in $( ls submodules ); do
  cd "submodules/$m"
  git checkout master
  git pull
  cd "${ROOT}"
done

#build command-t
#cd submodules/command-t/ruby/command-t
#make clean
#rm -f Makefile
#ruby extconf.rb
#make
#cd ../../../..
