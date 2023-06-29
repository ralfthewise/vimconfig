if !has('ruby')
  echo "Error: Juggler requires vim compiled with +ruby"
  finish
endif

if version < 700
  echo "Error: Juggler requires vim >= 7.0"
  finish
endif

"so that our ruby files can 'require' relative to this script
let s:plugin_path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

function juggler#Enable()
  imap <silent> <expr> <C-y> (pumvisible() ? <SID>UserCompleted("\<C-y>") : "\<C-y>")

  set lazyredraw "eliminate flickering
  call s:LoadRuby()
  call s:SetCompleteFunc()
  augroup Juggler
    autocmd!
    autocmd CursorMovedI * call juggler#UpdatePopup()
  augroup END
  nnoremap <silent> i i<C-r>=juggler#UpdatePopup()<CR>
  nnoremap <silent> a a<C-r>=juggler#UpdatePopup()<CR>
  nnoremap <silent> R R<C-r>=juggler#UpdatePopup()<CR>
  inoremap <silent> <expr> <C-h> <SID>OnBackspace("\<C-h>")
  inoremap <silent> <expr> <BS> <SID>OnBackspace("\<BS>")

  "initialize our completer singleton
  let s:indexespath = '' "will get updated by Juggler::Completer
  ruby Juggler::Completer.instance

  let s:indexesused = (s:indexespath != '')
  if s:indexesused
    "nmap <silent> <F12> :call <SID>UpdateIndexes(0, 0)<CR>
    augroup Juggler
      autocmd BufWritePost * call s:UpdateIndexes(0, 1)
    augroup END

    if g:juggler_useTagsCompleter && g:juggler_manageTags
      execute 'set tags=' . s:indexespath . '/tags'
      if !filereadable(s:indexespath . '/tags')
        call s:UpdateIndexes(1, 0)
      endif
    endif

    if g:juggler_useCscopeCompleter && g:juggler_manageCscope
      silent cscope kill -1
      if filereadable(s:indexespath . '/cscope.out')
        execute 'silent! cscope add ' . s:indexespath . '/cscope.out'
      else
        call s:UpdateIndexes(1, 0)
      endif
    endif
  endif

  if g:juggler_replaceCtrlpCommand
    ruby Juggler::Completer.instance.replace_ctrlp_user_command
  endif

  "set these initially so we can always count on them being set
  " let s:cursorinfo = {'linenum': -1, 'cursorindex': -1}
  let s:usercompleted = 0

  call s:SetupCommands()
  call s:SetupAutoCommands()
endfunction

function! s:OnBackspace(bsSeq)
  if pumvisible()
    return "\<C-e>" . a:bsSeq
  endif
  return a:bsSeq
endfunction

function! s:UpdateIndexes(quiet, onlyCurrentFile)
  let s:oldstatusline = &statusline
  if !a:onlyCurrentFile | set statusline=Updating\ indexes... | endif
  let rubyExec = 'ruby Juggler::Completer.instance.update_indexes(only_current_file: ' . a:onlyCurrentFile . ')'
  if a:quiet
    execute 'silent! ' . rubyExec
  else
    execute rubyExec
  endif

  if g:juggler_useCscopeCompleter && g:juggler_manageCscope
    if cscope_connection()
      silent! cscope reset
    else
      execute 'silent! cscope add ' . s:indexespath . '/cscope.out'
    endif
  endif
  if !a:onlyCurrentFile | let &statusline = s:oldstatusline | endif
  return ''
endfunction

function! s:UserCompleted(resetaction)
  "let's flag our state as in the process of completing due to user action
  "so that the next time a CursorMovedI event is fired we can ignore
  "it - not re-popup the menu right after the user dismissed it
  let s:usercompleted = 1

  return a:resetaction
endfunction

function! juggler#Complete(findstart, base)
  if !exists('s:cursorinfo')
    let s:cursorinfo = s:GetCursorInfo()
  endif

  if a:findstart
    ruby Juggler::Completer.instance.prepare_for_completions

    if !s:cursorinfo.match
      return -1 "indicates the completion should start at the cursor column
    endif

    "make sure omnifunc gets called if there is one
    if &omnifunc != "" && (g:juggler_useOmniCompleter || g:juggler_useOmniTrigger)
      "first save the current position and then move to start of token
      let save_cursor = getcurpos()
      call setpos('.', [save_cursor[0], save_cursor[1], save_cursor[2] - len(s:cursorinfo.token), save_cursor[3], save_cursor[4]])

      "call omnifunc
      call call(&omnifunc, [1, a:base])
      "TODO: should we return the result if it's valid?  And what
      "should we do if result differs from s:cursorinfo.matchstart?
      "let result = call(&omnifunc, [a:findstart, a:base])
      "if result
      "  return result
      "endif

      "restore original position
      call setpos('.', save_cursor)
    endif

    return s:cursorinfo.matchstart
  else
    let s:cursorinfo.base = a:base
    " return {'words': [], 'refresh': 'always'}
    return s:GetJugglerCompletions()
    " return v:none
  endif
endfunction

function juggler#UpdatePopup()
  if s:usercompleted
    let s:usercompleted = 0
  else
    if &modifiable && &buftype == ''
      let newcursofinfo = s:GetCursorInfo()
      if newcursofinfo.match && (!exists('s:cursorinfo') || newcursofinfo.linenum != s:cursorinfo.linenum || newcursofinfo.cursorindex != s:cursorinfo.cursorindex)
        let s:cursorinfo = newcursofinfo
        call feedkeys("\<C-x>\<C-u>\<C-R>=juggler#AfterPopup()\<CR>", 'n')
      else
        let s:cursorinfo = newcursofinfo
      endif
    endif
  endif
  return '' "have to return empty string otherwise '0' will get inserted
endfunction

function juggler#AfterPopup()
  if pumvisible()
    call feedkeys("\<C-p>\<Down>", 'n') "highlight first entry but leave originally typed text intact
  endif
  return '' "have to return empty string otherwise '0' will get inserted
endfunction

function! s:Search(defsrch)
  let resolvedsrch = (a:defsrch == '' ? expand('<cword>') : a:defsrch)
  let srchstr = input('Text to search for (start text with "/" to search for a regex): ', resolvedsrch)
  redraw
  let save_errorformat = &errorformat
  set errorformat=%f:%l:%c:%m
  ruby Juggler::Completer.instance.find()
  let &errorformat = save_errorformat
endfunction

function! s:GoToDefinition(defterm)
  let resolvedterm = (a:defterm == '' ? expand('<cword>') : a:defterm)
  exe 'cstag ' . resolvedterm
endfunction

function! s:ShowReferences(defterm)
  let resolvedterm = (a:defterm == '' ? expand('<cword>') : a:defterm)

  "normally we would just do 'cs find s ...' but unfortunately that always
  "jumps to the first match
  "exe 'cs find s ' . resolvedterm
  "copen

  let save_errorformat = &errorformat
  set errorformat=%f:%l:%m
  ruby Juggler::Completer.instance.show_references()
  let &errorformat = save_errorformat
endfunction

"Returns the following:
"  {
"    'match': <int>, " 0 or 1 - 1 indicates the text before the cursor matched one of the regexes thus triggering a completion
"    'type': <string>, " 'none', 'token', or 'omnitrigger' - which regex was matched
"    'linenum': <int>, " line of the cursor, first line is 1
"    'cursorindex': <int>, " column of the cursor, first column is 0
"    'token': <string>, " the text that matched the regex
"    'matchstart': <int>, " column where the regex started matching
"    'trigger': <string> " any additional match in the regex for an 'omnitrigger' match
"  }
function! s:GetCursorInfo()
  let line = getline('.')
  " let posinfo = getpos('.')
  let posinfo = getcursorcharpos()
  let cursorindex = posinfo[2] - 1
  let result = {'match': 0, 'type': 'none', 'linenum': posinfo[1], 'cursorindex': cursorindex, 'token': '', 'matchstart': 0, 'trigger': ''}
  if len(line) == 0
    return result
  endif
  " let cursorchar = line[cursorindex]

  let prefix = strpart(line, 0, cursorindex)
  "check for trigger token completion
  let matches = matchlist(prefix, g:juggler_triggerTokenRegex)
  if len(matches) > 1 && len(matches[1]) >= g:juggler_minTokenLength
    return {'match': 1, 'type': 'token', 'linenum': posinfo[1], 'cursorindex': cursorindex, 'token': matches[1], 'matchstart': cursorindex - len(matches[1])}
  endif
  "check for trigger omni completion
  if g:juggler_useOmniTrigger && &omnifunc != ""
    let matches = matchlist(prefix, g:juggler_triggerOmniRegex)
    if len(matches) > 2
      return {'match': 1, 'type': 'omnitrigger', 'linenum': posinfo[1], 'cursorindex': cursorindex, 'token': matches[2], 'matchstart': cursorindex - len(matches[2]), 'trigger': matches[1]}
    endif
  endif

  return result
endfunction

function! s:CallOmniFunc()
  if &omnifunc != ""
    return call(&omnifunc, [0, s:cursorinfo.base])
  endif
endfunction

function! s:SetCompleteFunc()
  let s:originalcomplete = eval('&completefunc')
  let &completefunc = 'juggler#Complete'
endfunction

function! s:ResetCompleteFunc()
  if exists('s:originalcomplete')
    let &completefunc = s:originalcomplete
    unlet s:originalcomplete
  endif
endfunction

function! s:GetJugglerCompletions()
  let s:juggler_completions = []
  ruby Juggler::Completer.instance.generate_completions
  return {'words': s:juggler_completions, 'refresh': 'always'}
  "return {'words': s:juggler_completions}
endfunction

function! s:GetTags(pat)
  return taglist(a:pat)
endfunction

function! s:GetKeywords(pat)
  redir => keyword_output
  silent! call s:KeywordTags(a:pat)
  redir END
  return keyword_output
endfunction

function! s:KeywordTags(pat)
  exe 'ilist! ' . a:pat

  " We used to be able to search all open buffers, but this is no longer
  " allowed - see https://github.com/vim/vim/issues/6017
  " We could consider just doing it all in ruby and caching all open buffers
  " there.

  " let buf = bufnr('')
  " let save_eventignore = &eventignore
  " set eventignore=all
  " exe 'bufdo ilist! ' . a:pat
  " let &eventignore = save_eventignore
  " exe 'b ' . buf
endfunction

function! s:GetCscope(pat)
  let save_cscopequickfix = &cscopequickfix
  set cscopequickfix=
  redir => cscope_output
  silent! call s:CscopeTags(a:pat)
  redir END
  let &cscopequickfix = save_cscopequickfix
  return cscope_output
endfunction

function! s:CscopeTags(pat)
  exe 'cs find e ' . a:pat
endfunction

function! s:SumBlock() range
  try
    let a_save = @a
    "first copy selection to a register
    silent! normal! gv"ay

    "call our sum function and then echo the result
    let s:juggler_sum_block = @a
    ruby Juggler::Completer.instance.sum_block
    echo s:juggler_sum_block
  finally
    let @a = a_save
  endtry
endfunction

function! s:LoadRuby()
ruby << RUBYEOF
  plugin_path = VIM::evaluate('s:plugin_path')
  require File.join(plugin_path, 'juggler.rb')
RUBYEOF
endfunction

function! s:SetupCommands()
  command! -n=0 JugglerHelp :help JugglerCommands
  command! -nargs=? JugglerSearch call s:Search('<args>')
  command! -nargs=? JugglerJumpDef call s:GoToDefinition('<args>')
  command! -nargs=? JugglerShowRefs call s:ShowReferences('<args>')
  command! -n=0 JugglerUpdateIndexes call s:UpdateIndexes(0, 0)
  command! -range -n=0 JugglerSumBlock call s:SumBlock()
  if g:juggler_setupMaps
    call s:SetupMaps()
  endif
endfunction

function! s:SetupMaps()
  nmap <F1> :JugglerHelp<CR>
  nmap <F3> :JugglerSearch<CR>
  nmap <C-B> :JugglerJumpDef<CR>
  nmap <F7> :JugglerShowRefs<CR>
endfunction

function! s:SetupAutoCommands()
  augroup Juggler
    autocmd BufReadPost * ruby Juggler::Completer.instance.file_opened_hook
    autocmd BufWritePost * ruby Juggler::Completer.instance.file_saved_hook
    autocmd TextChanged * ruby Juggler::Completer.instance.buffer_changed_hook
    autocmd TextChangedI * ruby Juggler::Completer.instance.buffer_changed_hook
    autocmd BufLeave * ruby Juggler::Completer.instance.buffer_left_hook
  augroup END
endfunction

"load additional functionality
exec 'source ' . s:plugin_path . '/ruby.vim'
