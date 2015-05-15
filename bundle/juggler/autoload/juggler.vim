if !has('ruby')
  echo "Error: Rubycomplete requires vim compiled with +ruby"
  finish
endif

if version < 700
  echo "Error: Required vim >= 7.0"
  finish
endif

"so that our ruby files can 'require' relative to this script
let s:plugin_path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

function juggler#Enable()
  inoremap <silent> <expr> <C-y> (pumvisible() ? juggler#UserCompleted("\<C-y>") : "\<C-y>")

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
  nmap <silent> <F12> :call <SID>UpdateTags()<CR>:cs reset<CR><CR>:redraw!<CR>:redrawstatus!<CR>

  "set these initially so we can always count on them being set
  let s:cursorinfo = {'linenum': -1, 'cursorindex': -1}
  let s:usercompleted = 0
endfunction

function! s:UpdateTags()
  silent !find . -type f -not -name 'cscope.*' -not -name 'tags' -not -path '*.git*' -not -path '*/vendor/*' -not -path '*/Godeps/*' -not -path '*/node_modules/*' -not -path '*/tmp/*' -not -path '*/dist/*' -exec grep -Il . {} ';' | ctags --fields=afmikKlnsStz --sort=foldcase -L- -f tags
  silent !find . -type f -not -name 'cscope.*' -not -name 'tags' -not -path '*.git*' -not -path '*/vendor/*' -not -path '*/Godeps/*' -not -path '*/node_modules/*' -not -path '*/tmp/*' -not -path '*/dist/*' -exec grep -Il . {} ';' | cscope -q -i - -b -U
  if cscope_connection()
    cscope reset
  else
    cscope add cscope.out
  endif
  return ''
endfunction

function! juggler#UserCompleted(resetaction)
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
    if !s:cursorinfo.match
      return 0
    endif

    "make sure omnifunc gets called if there is one
    if &omnifunc != ""
      call call(&omnifunc, [a:findstart, a:base])
      "TODO: should we return the result if it's valid?  And what
      "should we do if result differs from s:cursorinfo.matchstart?
      "let result = call(&omnifunc, [a:findstart, a:base])
      "if result
      "  return result
      "endif
    endif

    return s:cursorinfo.matchstart
  else
    let s:cursorinfo.base = a:base
    return s:GetJugglerCompletions()
  endif
endfunction

function juggler#UpdatePopup()
  if s:usercompleted
    let s:usercompleted = 0
  else
    if &modifiable && &buftype == ''
      let newcursofinfo = s:GetCursorInfo()
      if newcursofinfo.match && (newcursofinfo.linenum != s:cursorinfo.linenum || newcursofinfo.cursorindex != s:cursorinfo.cursorindex)
        let s:cursorinfo = newcursofinfo
        call feedkeys("\<C-x>\<C-u>\<C-R>=juggler#AfterPopup()\<CR>", 'n')
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

function! s:GetCursorInfo()
  let line = getline('.')
  if len(line) == 0
    return {'match': 0}
  endif

  let posinfo = getpos('.')
  let cursorindex = posinfo[2] - 1
  let cursorchar = line[cursorindex]
  if cursorindex < len(line) && cursorchar =~ '\w'
    return {'match': 0}
  endif

  let prefix = strpart(line, 0, cursorindex)
  let matches = matchlist(prefix, g:juggler_parseCurrentPosRegex)
  if len(matches) > 0 && (len(matches[1]) > 0 || len(matches[2]) >= g:juggler_minTokenLength)
    return {'match': 1, 'linenum': posinfo[1], 'cursorindex': cursorindex, 'prefix': matches[1], 'token': matches[2], 'matchstart': cursorindex - len(matches[2])}
  endif

  return {'match': 0}
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
  redir => ctag_output
  silent! call s:OutputTags(a:pat)
  redir END
  return ctag_output
endfunction

function! s:OutputTags(pat)
  "would like to do: taglist(a:pat)
  "but taglist() doesn't allow for case-insensitive matching
  "TODO: look into using '\c' in the search pattern for case insensitivity
  exe 'ts ' . a:pat
endfunction

function! s:GetKeywords(pat)
  redir => keyword_output
  silent! call s:KeywordTags(a:pat)
  redir END
  return keyword_output
endfunction

function! s:KeywordTags(pat)
  exe 'ilist ' . a:pat
endfunction

function! s:LoadRuby()
ruby << RUBYEOF
  plugin_path = VIM::evaluate('s:plugin_path')
  require File.join(plugin_path, 'juggler.rb')
RUBYEOF
endfunction
