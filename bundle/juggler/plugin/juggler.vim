if exists('g:juggler_loaded')
  finish
endif
let g:juggler_loaded = 1

function s:defineOption(name, default)
  if !exists(a:name)
    let {a:name} = a:default
  endif
endfunction

call s:defineOption('g:juggler_enableAtStartup', 1)
call s:defineOption('g:juggler_fixupPopupMenu', 1)
call s:defineOption('g:juggler_parseCurrentPosRegex', '\([\.:]*\)\(\w*\)$')
call s:defineOption('g:juggler_minTokenLength', 2)

if g:juggler_fixupPopupMenu
  inoremap <silent> <expr> <C-j> (pumvisible() ? "\<Down>" : "\<C-j>")
  inoremap <silent> <expr> <C-k> (pumvisible() ? "\<Up>" : "\<C-k>")
  imap <silent> <expr> <CR> (pumvisible() ? "\<C-y>" : "\<CR>")
  imap <silent> <expr> <Tab> (pumvisible() ? "\<C-y>" : "\<Tab>")
endif

if g:juggler_enableAtStartup
  call juggler#Enable()
endif
