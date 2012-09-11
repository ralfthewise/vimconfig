#!/bin/bash

cd submodules/vim-pathogen
git checkout master
git pull
cd ../..

cd submodules/AutoComplPop
git checkout master
git pull
cd ../..
