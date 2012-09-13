#!/bin/bash

cd submodules/vim-pathogen
git checkout master
git pull
cd ../..

cd submodules/AutoComplPop
git checkout master
git pull
cd ../..

cd submodules/vim-bufexplorer
git checkout master
git pull
cd ../..

cd submodules/nerdtree
git checkout master
git pull
cd ../..

cd submodules/genutils
git checkout master
git pull
cd ../..

cd submodules/vim-rails
git checkout master
git pull
cd ../..

cd submodules/syntastic
git checkout master
git pull
cd ../..

cd submodules/vim-coffee-script
git checkout master
git pull
cd ../..

cd submodules/command-t
git checkout master
git pull
cd ../..

cd submodules/taglist
git checkout master
git pull
cd ../..

cd submodules/ctrlp
git checkout master
git pull
cd ../..

#build command-t
cd submodules/command-t/ruby/command-t
make clean
rm -f Makefile
ruby extconf.rb
make
cd ../../../..
