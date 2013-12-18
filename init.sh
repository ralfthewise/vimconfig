#!/bin/bash

DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${DIR}"

git submodule init
git submodule update

##build command-t
#echo 'Building command-t.  Make sure you are building it against the version of ruby vim was built with (vim --version)...'
#cd submodules/command-t/ruby/command-t
#make clean
#rm Makefile
#ruby extconf.rb
#make
#cd ../../../..

#check for needed commands
command -v coffee >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo >&2 ''
  echo >&2 ''
  echo >&2 'coffee is not installed'
  echo >&2 'You can probably install it with "sudo apt-get install coffeescript"'
  echo >&2 ''
  echo >&2 ''
fi
command -v coffeelint >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo >&2 ''
  echo >&2 ''
  echo >&2 'coffeelint is not installed'
  echo >&2 'To install it you need to install node and npm, and then do "sudo npm install -g coffeelint"'
  echo >&2 ''
  echo >&2 ''
fi

echo ""
echo ""
echo ""
echo "Updating your vim environment to use this configuration..."

echo "  mkdir -p ~/.vimbackup ~/.vimswp ~/.vimundo"
mkdir -p ~/.vimbackup ~/.vimswp ~/.vimundo
echo "  rm -f ~/.vimrc.bak; mv ~/.vimrc ~/.vimrc.bak; ln -s \"${DIR}/vimrc\" ~/.vimrc"
rm -f ~/.vimrc.bak; mv ~/.vimrc ~/.vimrc.bak; ln -s "${DIR}/vimrc" ~/.vimrc
echo "  rm -f ~/.vim.bak; mv ~/.vim ~/.vim.bak; ln -s \"${DIR}\" ~/.vim"
rm -f ~/.vim.bak; mv ~/.vim ~/.vim.bak; ln -s "${DIR}" ~/.vim
echo "  rm -f ~/.ctags.bak; mv ~/.ctags ~/.ctags.bak; ln -s \"${DIR}/ctags\" ~/.ctags"
rm -f ~/.ctags.bak; mv ~/.ctags ~/.ctags.bak; ln -s "${DIR}/ctags" ~/.ctags

echo ""
echo "Installation complete."
