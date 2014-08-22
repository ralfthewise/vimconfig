vimconfig
=========

Vim plugins and .vimrc

After cloning the repository, run the "init.sh" script to install.

Keyboard Shortcuts
------------------

<table>
  <tr>
    <td>F4</td><td>Project explorer</td>
  </tr>
  <tr>
    <td>F5</td><td>Show classes, methods, variables of current file</td>
  </tr>
  <tr>
    <td>Ctrl-h</td><td>List open buffers and switch between them</td>
  </tr>
  <tr>
    <td>Ctrl-n</td><td>Find class</td>
  </tr>
  <tr>
    <td>Ctrl-m</td><td>Find file</td>
  </tr>
  <tr>
    <td>F12</td><td>Re-index project files</td>
  </tr>
</table>

Notes
-----

To add a new plugin, do:

    git submodule add https://github.com/scrooloose/nerdcommenter.git submodules/nerdcommenter
    cd bundle
    ln -s ../submodules/nerdcommenter
    cd ..
    ./init.sh
    git add bundle/nerdcommenter
    git commit -m 'add nerdcommenter submodule'
    git push

To update plugins do:

    ./update.sh
    git add -A submodules
    git commit -m 'update plugins'
    git push

Updating plugin documentation:

    open vim and do :Helptags
