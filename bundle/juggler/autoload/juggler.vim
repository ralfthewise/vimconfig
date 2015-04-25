if !has('ruby')
  echo "Error: Rubycomplete requires vim compiled with +ruby"
  finish
endif

if version < 700
  echo "Error: Required vim >= 7.0"
  finish
endif

function! juggler#Complete(findstart, base)
  if a:findstart
    " locate the start of the word
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\w'
      let start -= 1
    endwhile
    return start
  else
    if len(a:base) || &omnifunc == ""
      return s:GetJugglerCompletions(a:base)
    else
      echom 'using omni complete'
    endif
  endif
endfun

function! s:GetJugglerCompletions(base)
  let s:juggler_completions = []
  ruby Juggler::Completer.instance.generate_completions
  return s:juggler_completions
endfunction

function! s:GetTags(pat)
  redir => ctag_output
  silent! call s:OutputTags(a:pat)
  redir END
  return ctag_output
endfunction

fun! s:OutputTags(pat)
  "would like to do: taglist(a:pat)
  "but taglist() doesn't allow for case-insensitive matching
  exe 'ts ' . a:pat
endfun

function! s:LoadRuby()
ruby << RUBYEOF
  plugin_path = VIM::evaluate('s:plugin_path')
  require File.join(plugin_path, 'juggler.rb')
RUBYEOF
endfunction

let s:plugin_path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
call s:LoadRuby()
