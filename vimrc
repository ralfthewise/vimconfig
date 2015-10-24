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
"set mouse=a
"colorscheme mine256 "use mine256 colorscheme
colorscheme xoria256 "use xoria256 colorscheme
"colorscheme mustang "use mustang colorscheme
set modelines=2 "only look at the top 2 lines to check for modelines
set laststatus=2 "always show a status line
set backspace=indent,eol,start "make backspace work better
set cursorline "highlight line cursor is on
set cursorcolumn "highlight column cursor is on
set scrolloff=999 "keep current line centered vertically
set ai "autoindent - copy indent from current line when starting new line
set si "smartindent - add additional indent after {, if, def, etc.
set ts=2 sts=2 sw=2 et "tab/softtab = 2 spaces, shiftwidth (autoindent) = 2 spaces, insert spaces instead of tab.  these may be overridden by filetype plugins
filetype on "turn on filetype detection
filetype plugin on "when a filetype is detected, load the plugin for that filetype
filetype indent on "when a filetype is detected, load the indent for that filetype
set textwidth=0 "don't try to start a new line if current line starts to get really long
set wrapmargin=0 "don't wrap when we reach the right margin
set incsearch "incremental search
"set completeopt=longest,menuone,preview "in insert mode when doing completions, only insert longest common text, use popup menu even if only one match, show extra info about selected
set completeopt=menuone
set nohlsearch "don't highlight additional matches
"set ignorecase "ignore case when using ctags
set hidden "hide buffers rather than closing them when switching away from them
set history=1000 "remember more commands and search history
set undolevels=1000 "use many muchos levels of undo
set wildignore=vendor/bundle/**,tmp/**,*.gif,*.png,*.jpg,*.swp,*.bak,*.pyc,*.class,*.o,*.obj "when displaying/completing files/directories, ignore these patterns
set title "change the terminal's title
"set visualbell "flash screen instead of beeping
set noerrorbells "don't beep for error MESSAGES (errors still always beep)
"set clipboard=unnamedplus "use X11 clipboard as default
set verbosefile=/dev/null "discard all messages
redir >>/dev/null "redirect messages to null (sort of the same as above line)
let mapleader = "," "you can enter special commands with combinations that start with mapleader
set backupdir=~/.vimbackup,/tmp "where to store backup (~) files
set directory=~/.vimswp,/tmp "where to store swap (.swp) files
set undofile "allow undo across vim restarts
set undodir=~/.vimundo,/tmp "where to store undo (.udf) files
set ruler "show line,column,% of file in bottom line
autocmd BufReadPost quickfix nnoremap <buffer> <CR> <CR>:ccl<CR>
set wildmenu "vim command completion
set wildmode=longest:full,full "vim command completion

"load internal matchit plugin/macro
runtime macros/matchit.vim

"auto highlight word under cursor after 500 ms of idle
"augroup auto_highlight
"  au!
"  au CursorHold * let @/ = '\V\<'.escape(expand('<cword>'), '\').'\>'
"augroup end
"setl updatetime=750

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
"copy/cut to OS clipboard in visual/select mode
vmap Y "+y
vmap X "+x
"search for word under cursor
nnoremap <F6> :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>

"jump to the last position
"autocmd BufWinLeave * mkview
"autocmd BufWinEnter * silent loadview
"autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
"autocmd BufWritePost,BufLeave,WinLeave ?* if expand('%') != '' && &buftype !~ 'nofile' | mkview | endif
"autocmd BufWinEnter * if expand('%') != '[BufExplorer]' | silent loadview | endif
"autocmd BufWinEnter * if confirm(expand('%'), "&Yes\n&No", 2, "Question") == 1 | silent loadview | endif

"force unix line endings
"autocmd BufWinEnter * set fileformat=unix

"folding
set foldcolumn=4 "width of left column displaying info about folds
set foldlevelstart=1 "automatically fold any folds higher than this level
set fillchars=fold:\ 
"cause space to open a fold if you are on a line containing a fold, otherwise move right
nnoremap <silent> <Space> @=(foldlevel('.')?'za':'l')<CR>
"create a fold by selecting text and hitting space
vnoremap <Space> zf
"open all folds by hitting ctrl-space
"vnoremap <Nul> zR
"anytime a new buffer is opened set fold method to indent
"augroup vimrc
"  au BufReadPre * setlocal foldmethod=syntax
"augroup END
autocmd BufReadPost * :CollapseAll
"let SimpleFold_use_subfolds = 0

" Searching in files
" Use the Silver Searcher if possible
if executable('ag')
  " Use ag over grep
  set grepprg=ag\ --nogroup\ --nocolor\ --smart-case
endif
" Finding text in files
"command -nargs=+ -bar FindInFiles silent! grep! <args>|cwindow|redraw!
"nmap <F3> :JugglerFind<CR>
nmap <F3> :JugglerFind <C-R>=expand("<cword>")<CR><CR>

"code navigation
"find where method under cursor is called
nmap <F7> :cs find s <C-R>=expand("<cword>")<CR><CR>:copen<CR>
"jump to definition of method under cursor
"g<C-]> is part of the tags feature of vim - equivalent of :tjump <symbol
"under cursor> - means jump to definition or popup menu if more than 1 def
"nnoremap <C-b> g<C-]>
nmap <C-b> :cstag <C-R>=expand("<cword>")<CR><CR>

"acp
let g:juggler_enableAtStartup = 1
let g:juggler_logLevel = 'debug'
let g:juggler_useTagsCompleter = 1
let g:juggler_useCscopeCompleter = 1
let g:juggler_useOmniCompleter = 1
let g:juggler_additionalPathExcludes = ['*/test-ui/reports/*']
let g:acp_enableAtStartup = 0
let g:acp_completeoptPreview = 1

"syntastic
let g:syntastic_go_checkers = ['golint', 'govet']

"vim-expand-region
let g:expand_region_text_objects_ruby = {
      \ 'iw' :0,
      \ 'iW' :0,
      \ 'i"' :0,
      \ 'i''':0,
      \ 'i]' :1,
      \ 'ib' :1,
      \ 'iB' :1,
      \ 'ir' :1,
      \ 'ar' :1,
      \ }
"call expand_region#custom_text_objects('ruby', {
"      \ 'ir' :1,
"      \ 'ar' :1,
"      \ })

"command-t
"nnoremap <silent> <C-n> :CommandTTag<CR>
"nnoremap <silent> <C-m> :CommandT<CR>
"let g:CommandTMatchWindowAtTop = 1

"ctrlp
let g:ctrlp_working_path_mode = '0'
let g:ctrlp_map = '<C-@>'
"let g:ctrlp_cmd = 'CtrlPMixed' "careful here, when searching MRU it is across all sessions/historical MRUs
let g:ctrlp_extensions = ['tag']
"let g:ctrlp_custom_ignore = '\v(\.git|\.hg|\.svn|tmp\/|vendor\/bundle|bower_components\/|node_modules\/|app\/components\/|Godeps\/|log\/)'
let g:ctrlp_custom_ignore = '\v(\.git|\.hg|\.svn|tmp\/|vendor\/bundle|bower_components\/|node_modules\/|Godeps\/|log\/)'
"let g:ctrlp_match_func = {'match':'ctrlpmatcher#MatchIt'}
let g:ctrlpmatcher_debug = 0
nnoremap <silent> <C-t> :CtrlPTag<CR>
"nnoremap <silent> <Nul> :CtrlP<CR>
set timeout timeoutlen=1000 ttimeoutlen=100
"set <F13>=[1;5S
set <F13>=O1;5S
nmap <F13> :TagbarToggle<CR>

"taglist
"let g:Tlist_Show_One_File = 1
"let g:Tlist_Close_On_Select = 1
"let g:Tlist_Exit_OnlyWindow = 1
"let g:Tlist_Process_File_Always = 1
"let g:Tlist_Sort_Type = "name"
"let g:Tlist_WinWidth = 60
"let g:tlist_coffee_settings = 'coffee;c:class;f:function;v:variable'
"nnoremap <silent> <F5> :TlistOpen<CR>

"tagbar
let g:tagbar_left = 1
let g:tagbar_autoclose = 1
let g:tagbar_autofocus = 1
let g:tagbar_width = 60
let g:tagbar_sort = 1
let g:tagbar_compact = 1
nnoremap <silent> <F5> :TagbarToggle<CR>
let g:tagbar_type_coffee = {
    \ 'ctagstype' : 'coffee',
    \ 'kinds'     : [
        \ 'c:classes',
        \ 'm:methods',
        \ 'f:functions',
        \ 'v:variables',
        \ 'f:fields',
    \ ]
\ }
let g:tagbar_type_go = {
    \ 'ctagstype' : 'go',
    \ 'kinds'     : [
        \ 'p:package',
        \ 'i:imports:1',
        \ 'c:constants',
        \ 'v:variables',
        \ 't:types',
        \ 'n:interfaces',
        \ 'w:fields',
        \ 'e:embedded',
        \ 'm:methods',
        \ 'r:constructor',
        \ 'f:functions'
    \ ],
    \ 'sro' : '.',
    \ 'kind2scope' : {
        \ 't' : 'ctype',
        \ 'n' : 'ntype'
    \ },
    \ 'scope2kind' : {
        \ 'ctype' : 't',
        \ 'ntype' : 'n'
    \ },
    \ 'ctagsbin'  : 'gotags',
    \ 'ctagsargs' : '-sort -silent'
\ }

"showmarks
"let g:showmarks_textupper=">"
"let g:showmarks_textlower=">>"
"hi default ShowMarksHLl ctermfg=white ctermbg=blue cterm=bold guifg=white guibg=blue gui=bold
"hi default ShowMarksHLu ctermfg=white ctermbg=blue cterm=bold guifg=white guibg=blue gui=bold
"hi default ShowMarksHLo ctermfg=white ctermbg=blue cterm=bold guifg=white guibg=blue gui=bold
"hi default ShowMarksHLm ctermfg=white ctermbg=blue cterm=bold guifg=white guibg=blue gui=bold

"vim-bookmarks
let g:bookmark_save_per_working_dir = 1
let g:bookmark_auto_save = 1
let g:bookmark_auto_close = 1

"BufferExplorer
nnoremap <silent> <C-h> :BufExplorer<CR>j

"NERDTree
let g:NERDTreeQuitOnOpen = 1
let g:NERDChristmasTree = 1
let g:NERDTreeWinSize = 48
nnoremap <silent> <F4> :NERDTreeFind<CR>

"NERDCommenter
"have to do these two to prevent the plugin from overriding our '<leader>cc'
"mappings below
nmap <leader>c6 <plug>NERDCommenterComment
xmap <leader>c6 <plug>NERDCommenterComment

",cc to comment a line or selected block
nmap <leader>cc <plug>NERDCommenterAlignLeft
xmap <leader>cc <plug>NERDCommenterAlignLeft
",cu to uncomment a line or selected block - already done natively by NERDCommenter

"cscope
set cscopetag " use both cscope and ctag for 'ctrl-]', ':ta', and 'vim -t'
set csto=1 " check tags for definition of a symbol before checking cscope
" add cscope db
if filereadable("cscope.out")
  cs add cscope.out
elseif $CSCOPE_DB != ""
  cs add $CSCOPE_DB
endif
set cscopeverbose " show msg when any other cscope db added
set cscopequickfix=s-,c-,d-,i-,t-,e- "blow away all previous quickfix entries for all types of cscope searches
"jump to next quickfix entry and redisplay the quickfix list
nnoremap <C-j> :cn<CR>:copen<CR>
"jump to previous quickfix entry and redisplay the quickfix list
nnoremap <C-k> :cp<CR>:copen<CR>

"EasyMotion
"move down by lines
vmap <leader>j :<C-U>call EasyMotion#JK(1, 0)<CR>
omap <leader>j :call EasyMotion#JK(0, 0)<CR>
nmap <leader>j :call EasyMotion#JK(0, 0)<CR>
"move up by lines
vmap <leader>k :<C-U>call EasyMotion#JK(1, 1)<CR>
omap <leader>k :call EasyMotion#JK(0, 1)<CR>
nmap <leader>k :call EasyMotion#JK(0, 1)<CR>
"move forward by words
vmap <leader>w :<C-U>call EasyMotion#WB(1, 0)<CR>
omap <leader>w :call EasyMotion#WB(0, 0)<CR>
nmap <leader>w :call EasyMotion#WB(0, 0)<CR>
"move backward by words
vmap <leader>b :<C-U>call EasyMotion#WB(1, 1)<CR>
omap <leader>b :call EasyMotion#WB(0, 1)<CR>
nmap <leader>b :call EasyMotion#WB(0, 1)<CR>

"filetypes
au BufRead,BufNewFile *.jst.ejs set filetype=html
au BufRead,BufNewFile *.jst.str set filetype=html
au BufRead,BufNewFile *.hbs set filetype=html

"language specific stuff
"ruby
"function s:add_global_ruby_cscope()
"  if filereadable($HOME . "/.ruby.cscope") && !cscope_connection(2, $HOME . "/.ruby.cscope")
"    cscope add ~/.ruby.cscope
"  endif
"endfunction
"autocmd FileType ruby,eruby call s:add_global_ruby_cscope()
"autocmd FileType ruby,eruby set omnifunc=rubycomplete#Complete
"autocmd FileType ruby,eruby set tags=ruby.tags
autocmd FileType ruby,eruby let g:rubycomplete_buffer_loading = 1
autocmd FileType ruby,eruby let g:rubycomplete_rails = 1
autocmd FileType ruby,eruby let g:rubycomplete_classes_in_global = 1
autocmd FileType ruby set iskeyword=@,48-57,_,?,!,192-255

"vim
autocmd FileType vim call Collapse_SetRegexs('^\s*function!\?', '^\s*endfunction\s*$', '^\s*"')

"python
autocmd FileType python call Collapse_SetRegexs('^\s*def\s', '', '^\s*#')
autocmd FileType python setl ts=4 sts=4 sw=4 et
"function s:add_global_python_cscope()
"  if filereadable($HOME . "/.python.cscope") && !cscope_connection(2, $HOME . "/.python.cscope")
"    cscope add ~/.python.cscope
"  endif
"endfunction
"autocmd FileType python call s:add_global_python_cscope()
"autocmd FileType python set tags=python.tags,~/.python.ctags
autocmd FileType python set omnifunc=pythoncomplete#Complete
"autocmd FileType python nnoremap <silent> <C-F12> :!find /usr/lib/python`python -c 'import sys; print sys.version[:3]'` -name '*.py' -perm -444\| cscope -f ~/.python.cscope -q -i - -b<CR>:cs reset<CR><CR>
"autocmd FileType python nnoremap <silent> <C-F12> :!find /usr/lib/python`python -c 'import sys; print sys.version[:3]'` -name '*.py' -perm -444\| ctags --sort=foldcase -f ~/.python.ctags -L-<CR>

"coffeescript
"autocmd FileType coffee set tags=coffee.tags

"json
autocmd FileType json autocmd BufWritePre <buffer> %!python -m json.tool

"c/c++
autocmd FileType c setl ts=2 sts=2 sw=2 et
"autocmd FileType c set tags=c.tags
autocmd FileType c set omnifunc=ccomplete#Complete

"go
"if exists("g:did_load_filetypes")
"  filetype off
"  filetype plugin indent off
"endif
"set runtimepath+=$GOROOT/misc/vim " replace $GOROOT with the output of: go env GOROOT
"filetype plugin indent on
"syntax on
let g:go_fmt_command = "goimports"
autocmd FileType go highlight clear ExtraWhitespace
autocmd FileType go setl ts=2 sts=2 sw=2 noexpandtab
"autocmd FileType go set tags=.go.tags,~/.go.tags
"autocmd FileType go set tags=.go.tags
