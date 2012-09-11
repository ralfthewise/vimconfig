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
