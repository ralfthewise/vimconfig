"some hints
"replace all tabs in file with spaces:
":retab

"should come first since it changes other options
set nocompatible "use vim defaults, not vi defaults

"initialize pathogen (manage vim scripts in their own directory)
call pathogen#infect()
call pathogen#helptags()

"whitespace - has to come before other ColorScheme commands
autocmd ColorScheme * highlight ExtraWhitespace ctermbg=darkred guibg=darkred "color of bad whitespace
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$\|\t/ "insert mode don't match trailing whitespace
autocmd InsertLeave * match ExtraWhitespace /\s\+$\|\t/ "non-insert mode match all whitespace
autocmd BufWinEnter * match ExtraWhitespace /\s\+$\|\t/ "opening a new buffer match all whitespace
"set list "tabs show as CTRL-I, end of line shows as $
"set listchars=tab:>.,trail:.,extends:#,nbsp:. "tab = >., trailing space = ., line extends past screen = #, non-breakable space = .

"misc
syntax enable "enable syntax highlighting
set t_Co=256 "force vim to assume our terminal can display 256 colors
set background=dark "use colors that look good on a dark background
set mouse=a
"colorscheme mine256 "use mine256 colorscheme
colorscheme xoria256 "use xoria256 colorscheme
"colorscheme mustang "use mustang colorscheme
set cursorline "highlight line cursor is on
set ai "autoindent - copy indent from current line when starting new line
set si "smartindent - add additional indent after {, if, def, etc.
set ts=2 sts=2 sw=2 et "tab/softtab = 2 spaces, shiftwidth (autoindent) = 2 spaces, insert spaces instead of tab.  these may be overridden by filetype plugins
filetype on "turn on filetype detection
filetype plugin on "when a filetype is detected, load the plugin for that filetype
filetype indent on "when a filetype is detected, load the indent for that filetype
set textwidth=0 "don't try to start a new line if current line starts to get really long
set wrapmargin=0 "don't wrap when we reach the right margin
set incsearch "incremental search
set completeopt=longest,menuone,preview "in insert mode when doing completions, only insert longest common text, use popup menu even if only one match, show extra info about selected
set nohlsearch "don't highlight additional matches
"set ignorecase "ignore case when using ctags
set hidden "hide buffers rather than closing them when switching away from them
set history=1000 "remember more commands and search history
set undolevels=1000 "use many muchos levels of undo
set wildignore=vendor/bundle/**,*.gif,*.png,*.jpg,*.swp,*.bak,*.pyc,*.class,*.o,*.obj "when displaying/completing files/directories, ignore these patterns
set title "change the terminal's title
"set visualbell "flash screen instead of beeping
set noerrorbells "don't beep for error MESSAGES (errors still always beep)
set verbosefile=/dev/null "discard all messages
redir >>/dev/null "redirect messages to null (sort of the same as above line)
let mapleader = "," "you can enter special commands with combinations that start with mapleader

"mappings
"inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
"inoremap <expr> <C-n> pumvisible() ? '<C-n>' : '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
""inoremap <expr> <Nul> pumvisible() \|\| &omnifunc == "" ? "\<C-n>\<Down>" : "\<C-x>\<C-o>\<Down>"
"inoremap <silent> <expr> <Nul> pumvisible() ? '<Down>' : '<C-r>=&omnifunc == "" ? "\<lt>C-n>\<lt>Down>" : "\<lt>C-x>\<lt>C-o>\<lt>Down>"<CR>'
"so you don't have to push and release 'Shift' when typing vim commands
nnoremap ; :
"'j' moves down a row instead of down a line (useful when really long text wraps)
nnoremap j gj
"same as above for 'k'
nnoremap k gk
" redo
nmap U :later 1<CR>
" Auto-indent whole file
nmap <leader>= gg=G``
" Jump to a new line in insert mode
imap <D-CR> <Esc>o
"esc is too far away!
imap kj <Esc>

"jump to the last position
autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

"folding
set foldcolumn=4 "width of left column displaying info about folds
set foldlevelstart=1 "automatically fold any folds higher than this level
set fillchars=fold:\ 
"cause space to open a fold if you are on a line containing a fold, otherwise move right
nnoremap <silent> <Space> @=(foldlevel('.')?'za':'l')<CR>
"create a fold by selecting text and hitting space
vnoremap <Space> zf
"open all folds by hitting ctrl-space
vnoremap <Nul> zR
"anytime a new buffer is opened set fold method to indent
"augroup vimrc
"  au BufReadPre * setlocal foldmethod=syntax
"augroup END
autocmd BufReadPost * :CollapseAll
"let SimpleFold_use_subfolds = 0


"code navigation
"find where method under cursor is called
"nnoremap <F7> :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <F7> :cs find s <C-R>=expand("<cword>")<CR><CR>:cl!<CR>
"jump to definition of method under cursor
"g<C-]> is part of the tags feature of vim - equivalent of :tjump <symbol
"under cursor> - means jump to definition or popup menu if more than 1 def
"nnoremap <C-b> g<C-]>
nmap <C-b> :cstag <C-R>=expand("<cword>")<CR><CR>

"acp
let g:acp_completeoptPreview = 1

"command-t
"nnoremap <silent> <C-n> :CommandTTag<CR>
"nnoremap <silent> <C-m> :CommandT<CR>
"let g:CommandTMatchWindowAtTop = 1

"ctrlp
let g:ctrlp_extensions = ['tag']
let g:ctrlp_custom_ignore = '\v(\.git|\.hg|\.svn|vendor\/bundle)'
let g:ctrlp_match_func = {'match':'ctrlpmatcher#MatchIt'}
let g:ctrlpmatcher_debug = 0
nnoremap <silent> <C-n> :CtrlPTag<CR>
nnoremap <silent> <C-m> :CtrlP<CR>

"taglist
let g:Tlist_Show_One_File = 1
let g:Tlist_Close_On_Select = 1
let g:Tlist_Exit_OnlyWindow = 1
let g:Tlist_Process_File_Always = 1
let g:Tlist_Sort_Type = "name"
let g:Tlist_WinWidth = 60
let g:tlist_coffee_settings = 'coffee;c:class;f:function;v:variable'
nnoremap <silent> <F5> :TlistOpen<CR>

"showmarks
"let g:showmarks_textupper=">"
"let g:showmarks_textlower=">>"
"hi default ShowMarksHLl ctermfg=white ctermbg=blue cterm=bold guifg=white guibg=blue gui=bold
"hi default ShowMarksHLu ctermfg=white ctermbg=blue cterm=bold guifg=white guibg=blue gui=bold
"hi default ShowMarksHLo ctermfg=white ctermbg=blue cterm=bold guifg=white guibg=blue gui=bold
"hi default ShowMarksHLm ctermfg=white ctermbg=blue cterm=bold guifg=white guibg=blue gui=bold

"BufferExplorer
nnoremap <silent> <C-h> :BufExplorer<CR>j

"NERDTree
let g:NERDTreeQuitOnOpen = 1
let g:NERDChristmasTree = 1
let g:NERDTreeWinSize = 48
nnoremap <silent> <F4> :NERDTreeFind<CR>

"cscope
"blow away all previous quickfix entries for all types of cscope searches
set cscopequickfix=s-,c-,d-,i-,t-,e-
"jump to next quickfix entry and redisplay the quickfix list
nnoremap <C-j> :cn<CR>:cl!<CR>
"jump to previous quickfix entry and redisplay the quickfix list
nnoremap <C-k> :cp<CR>:cl!<CR>

"filetypes
au BufRead,BufNewFile *.jst.ejs set filetype=html
au BufRead,BufNewFile *.hbs set filetype=html

"language specific stuff
"ruby
function s:add_global_ruby_cscope()
  if filereadable($HOME . "/.ruby.cscope") && !cscope_connection(2, $HOME . "/.ruby.cscope")
    cscope add ~/.ruby.cscope
  endif
endfunction
"autocmd FileType ruby,eruby call s:add_global_ruby_cscope()
"autocmd FileType ruby,eruby set omnifunc=rubycomplete#Complete
autocmd FileType ruby,eruby set tags=ruby.tags
autocmd FileType ruby,eruby let g:rubycomplete_buffer_loading = 1
autocmd FileType ruby,eruby let g:rubycomplete_rails = 1
autocmd FileType ruby,eruby let g:rubycomplete_classes_in_global = 1
autocmd FileType ruby set iskeyword=@,48-57,_,?,!,192-255
autocmd FileType ruby,eruby nnoremap <silent> <F12> :!find . -not -path '*vendor/bundle*' -a \( -iname '*.rb' -o -iname '*.erb' -o -iname '*.rhtml' \) \| ctags --fields=afmikKlnsStz --sort=foldcase -L- -f ruby.tags<CR>:!find . -not -path '*vendor/bundle*' -a \( -iname '*.rb' -o -iname '*.erb' -o -iname '*.rhtml' \) \| cscope -q -i - -b<CR>:cs reset<CR><CR>

"vim
autocmd FileType vim call Collapse_SetRegexs('^\s*function!\?', '^\s*endfunction\s*$', '^\s*"')

"python
autocmd FileType python call Collapse_SetRegexs('^\s*def\s', '', '^\s*#')
autocmd FileType python setl ts=4 sts=4 sw=4 et
function s:add_global_python_cscope()
  if filereadable($HOME . "/.python.cscope") && !cscope_connection(2, $HOME . "/.python.cscope")
    cscope add ~/.python.cscope
  endif
endfunction
"autocmd FileType python call s:add_global_python_cscope()
autocmd FileType python set tags=python.tags,~/.python.ctags
autocmd FileType python set omnifunc=pythoncomplete#Complete
"autocmd FileType python nnoremap <silent> <C-F12> :!find /usr/lib/python`python -c 'import sys; print sys.version[:3]'` -name '*.py' -perm -444\| cscope -f ~/.python.cscope -q -i - -b<CR>:cs reset<CR><CR>
autocmd FileType python nnoremap <silent> <C-F12> :!find /usr/lib/python`python -c 'import sys; print sys.version[:3]'` -name '*.py' -perm -444\| ctags --sort=foldcase -f ~/.python.ctags -L-<CR>
autocmd FileType python nnoremap <silent> <F12> :!find . -iname '*.py' \| ctags --sort=foldcase -L- -f python.tags<CR>:!find . -iname '*.py' \| cscope -q -i - -b<CR>:cs reset<CR><CR>

"coffeescript
autocmd FileType coffee set tags=coffee.tags
autocmd FileType coffee nnoremap <silent> <F12> :!find . -not -path '*vendor/bundle*' -a -iname '*\.coffee*' \| ctags -L- -f coffee.tags<CR><CR>

"c/c++
autocmd FileType c setl ts=2 sts=2 sw=2 et
autocmd FileType c set tags=c.tags
autocmd FileType c set omnifunc=ccomplete#Complete
autocmd FileType c nnoremap <silent> <F12> :!find . -iname '*.c' -o -iname '*.h' -o -iname '*.cpp' \| ctags --sort=foldcase -L- -f c.tags<CR>:!find . -iname '*.c' -o -iname '*.h' -o -iname '*.cpp' \| cscope -q -i - -b<CR>:cs reset<CR><CR>
