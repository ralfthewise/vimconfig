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
  \'*.idea/*',
  \'*.git/*',
  \'*.hg/*',
  \'*.svn/*',
  \'*/log/*',
  \'*/tmp/*',
  \'*/dist/*',
  \'*/vendor/*',
  \'*/coverage/*',
  \'*/Godeps/*',
  \'*/yarn.lock',
  \'*/package-lock.json',
  \'*/node_modules/*',
  \'*/bower_components/*',
  \'*/platforms/*',
  \'*/plugins/*',
  \'*/www/*',
  \'*/venv/*',
\]
call s:defineOption('g:juggler_additionalPathExcludes', [])
call s:defineOption('g:juggler_pathExcludes', g:juggler_defaultPathExcludes + g:juggler_additionalPathExcludes)

call s:defineOption('g:juggler_enableAtStartup', 1)
call s:defineOption('g:juggler_setupMaps', 1)
call s:defineOption('g:juggler_logLevel', 'error')
call s:defineOption('g:juggler_fixupPopupMenu', 1)

"Will trigger completion if the text before the cursor matches the regex
"below and the matched text is >= the min token length.
call s:defineOption('g:juggler_triggerTokenRegex', '\(\w\+\)$')
call s:defineOption('g:juggler_minTokenLength', 2)

"Use omni completion when doing token completion
call s:defineOption('g:juggler_useOmniCompleter', 0)
"Allow omni completion to be triggered by its own regex (eg after typing '.'
"or '::')
call s:defineOption('g:juggler_useOmniTrigger', 1)
"Regex that will trigger just language aware (LSP and OmniCompleter) completions
call s:defineOption('g:juggler_triggerOmniRegex', '\(\%(->\|\.\|::\|<\)\)$')
"If doing omni trigger completion, should we cache the results and use them
"for successive token completions
call s:defineOption('g:juggler_useOmniTriggerCache', 1)

call s:defineOption('g:juggler_language_plugins', {})

call s:defineOption('g:juggler_useTagsCompleter', 1)
call s:defineOption('g:juggler_manageTags', 1)
call s:defineOption('g:juggler_useCscopeCompleter', 1)
call s:defineOption('g:juggler_manageCscope', 1)
call s:defineOption('g:juggler_useKeywordCompleter', 1)
call s:defineOption('g:juggler_useLSPCompleter', 1)

call s:defineOption('g:juggler_replaceCtrlpCommand', 1)

if g:juggler_fixupPopupMenu
  inoremap <silent> <expr> <C-j> (pumvisible() ? "\<Down>" : "\<C-j>")
  inoremap <silent> <expr> <C-k> (pumvisible() ? "\<Up>" : "\<C-k>")
  imap <silent> <expr> <CR> (pumvisible() ? "\<C-y>" : "\<CR>")
  imap <silent> <expr> <Tab> (pumvisible() ? "\<C-y>" : "\<Tab>")
endif

if g:juggler_enableAtStartup
  call juggler#Enable()
endif
