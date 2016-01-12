#!/bin/bash

DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${DIR}"

echo "  mkdir -p ~/.vim ~/.vimbackup ~/.vimswp ~/.vimundo"
mkdir -p ~/.vim  ~/.vimbackup ~/.vimswp ~/.vimundo

if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi

#check for needed commands
command -v coffee >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo >&2 ''
  echo >&2 ''
  echo >&2 'coffee is not installed'
  echo >&2 'You can probably install it with "sudo npm install -g coffee-script"'
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
command -v gotags >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo >&2 ''
  echo >&2 ''
  echo >&2 'gotags is not installed'
  echo >&2 'To install it you need to install go, setup your GOPATH, and then do "go get -u github.com/jstemmer/gotags"'
  echo >&2 ''
  echo >&2 ''
fi

echo ""
echo ""
echo ""
echo "Updating your vim environment to use this configuration..."

echo "  rm -f ~/.vimrc.bak; mv ~/.vimrc ~/.vimrc.bak; ln -s \"${DIR}/vimrc\" ~/.vimrc"
rm -f ~/.vimrc.bak; mv ~/.vimrc ~/.vimrc.bak; ln -s "${DIR}/vimrc" ~/.vimrc
echo "  rm -f ~/.vim/colors.bak; mv ~/.vim/colors ~/.vim/colors.bak; ln -s \"${DIR}/colors\" ~/.vim/colors"
rm -f ~/.vim/colors.bak; mv ~/.vim/colors ~/.vim/colors.bak; ln -s "${DIR}/colors" ~/.vim/colors
echo "  rm -f ~/.ctags.bak; mv ~/.ctags ~/.ctags.bak; ln -s \"${DIR}/ctags\" ~/.ctags"
rm -f ~/.ctags.bak; mv ~/.ctags ~/.ctags.bak; ln -s "${DIR}/ctags" ~/.ctags


vim +PluginInstall +qall
vim -c "helptags ${HOME}/.vim/bundle/Vundle.vim/doc|q"

echo ""
echo "Installation complete."
