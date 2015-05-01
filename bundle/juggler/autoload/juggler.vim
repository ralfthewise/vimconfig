if !has('ruby')
  echo "Error: Rubycomplete requires vim compiled with +ruby"
  finish
endif

if version < 700
  echo "Error: Required vim >= 7.0"
  finish
endif

function juggler#Enable()
  augroup Juggler
    autocmd!
    autocmd CursorMovedI * call juggler#UpdatePopup()
  augroup END
endfunction

function! juggler#Complete(findstart, base)
  let s:compstart = a:findstart
  let s:compbase = a:base

  if a:findstart
    echom 'determining start of juggler completion word'
    " locate the start of the word
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\w'
      let start -= 1
    endwhile

    "make sure omnifunc gets called if there is one
    if &omnifunc != ""
      return call(&omnifunc, [a:findstart, a:base])
    endif
    return start
  else
    return s:GetJugglerCompletions(a:base)
  endif
endfunction

function juggler#UpdatePopup()
  call s:SetCompleteFunc()
  call feedkeys("\<C-x>\<C-u>\<C-p>\<Down>", 'n') "highlight first entry but leave originally typed text intact
  return '' "have to return empty string otherwise '0' will get inserted
endfunction

function! s:CallOmniFunc()
  if &omnifunc != ""
    return call(&omnifunc, [s:compstart, s:compbase])
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

function! s:GetJugglerCompletions(base)
  let s:juggler_completions = []
  ruby Juggler::Completer.instance.generate_completions
  return {'words': s:juggler_completions, 'refresh': 'always'}
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
  exe 'ts ' . a:pat
endfunction

function! s:LoadRuby()
ruby << RUBYEOF
  plugin_path = VIM::evaluate('s:plugin_path')
  require File.join(plugin_path, 'juggler.rb')
RUBYEOF
endfunction

let s:plugin_path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
call s:LoadRuby()
