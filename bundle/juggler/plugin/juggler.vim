if exists('g:juggler_loaded')
  finish
endif
let g:juggler_loaded = 1

function s:defineOption(name, default)
  if !exists(a:name)
    let {a:name} = a:default
  endif
endfunction

let g:juggler_defaultPathExcludes = [
  \'*/cscope.*',
  \'*/tags',
  \'*.git*',
  \'*.hg*',
  \'*.svn*',
  \'*/log/*',
  \'*/tmp/*',
  \'*/dist/*',
  \'*/vendor/*',
  \'*/Godeps/*',
  \'*/node_modules/*',
  \'*/bower_components/*',
\]
call s:defineOption('g:juggler_additionalPathExcludes', [])
call s:defineOption('g:juggler_pathExcludes', g:juggler_defaultPathExcludes + g:juggler_additionalPathExcludes)

call s:defineOption('g:juggler_enableAtStartup', 1)
call s:defineOption('g:juggler_logLevel', 'error')
call s:defineOption('g:juggler_fixupPopupMenu', 1)
call s:defineOption('g:juggler_parseCurrentPosRegex', '\([\.:]*\)\(\w*\)$')
call s:defineOption('g:juggler_minTokenLength', 2)

call s:defineOption('g:juggler_useOmniCompleter', 0)
call s:defineOption('g:juggler_useTagsCompleter', 1)
call s:defineOption('g:juggler_manageTags', 1)
call s:defineOption('g:juggler_useCscopeCompleter', 1)
call s:defineOption('g:juggler_manageCscope', 1)
call s:defineOption('g:juggler_useKeywordCompleter', 1)

if g:juggler_fixupPopupMenu
  inoremap <silent> <expr> <C-j> (pumvisible() ? "\<Down>" : "\<C-j>")
  inoremap <silent> <expr> <C-k> (pumvisible() ? "\<Up>" : "\<C-k>")
  imap <silent> <expr> <CR> (pumvisible() ? "\<C-y>" : "\<CR>")
  imap <silent> <expr> <Tab> (pumvisible() ? "\<C-y>" : "\<Tab>")
endif

if g:juggler_enableAtStartup
  call juggler#Enable()
endif

command! -nargs=? JugglerFind call juggler#Find('<args>')
