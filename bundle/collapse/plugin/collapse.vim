" Vim global plugin for flexible folding
" Last Change:  2011 Mar 22
" Maintainer: Tim Garton <tim@datastarved.net>
" License:

" only load once
if exists('loaded_collapse')
  finish
endif
let loaded_collapse = 1

" avoid issues with compatible mode
let s:save_cpo = &cpo
set cpo&vim

" set some initial variables
let s:regex_start = '^\s*def\s'
let s:regex_end = '^\s*end\s*$'
let s:regex_comment = '^\s*#'
let s:regex_blank_line = '^\s*$'
let s:regex_extract_foldtext = '^\s*\(.\{-}\)\s*$'

" figure out our SID
map <SID>xx <SID>xx
let s:sid = maparg("<SID>xx")
unmap <SID>xx
let s:sid = substitute(s:sid, 'xx', '', '')

" do it
function! Collapse_SetRegexs(regex_start, regex_end, regex_comment)
  let s:regex_start = a:regex_start
  let s:regex_end = a:regex_end
  let s:regex_comment = a:regex_comment
endfunction

function! s:CollapseFoldText()
  let linenum = v:foldstart
  while linenum <= v:foldend
    if getline(linenum) =~ s:regex_start
      break
    endif
    let linenum = linenum + 1
  endwhile
  if linenum > v:foldend
    let linenum = v:foldstart
  endif
  let foldstart = substitute(getline(linenum), s:regex_extract_foldtext, '\1', '')
  return printf('%s %3d lines: %s', v:folddashes, v:foldend - v:foldstart, foldstart)
  "return (v:foldend - v:foldstart) . ' lines: ' . foldstart
endfunction

function! s:CollapseAll()
  setlocal fdm=manual
  execute 'setlocal foldtext=' . s:sid . 'CollapseFoldText()'
  let linenum = 0
  let last_linenum = line('$')
  while linenum < last_linenum
    let line = getline(linenum)
    if getline(linenum) =~ s:regex_start
      let linenum = s:CreateFold(linenum)
    else
      let linenum = linenum + 1
    endif
  endwhile

  " open current fold if we're in one
  if foldlevel('.') > 0
    normal za
  endif
endfunction

function! s:CreateFold(startline)
  "echo 'CreateFold called with ' . a:startline . ' as the startline'
  let last_linenum = line('$')
  let endline = a:startline + 1
  let startindent = indent(a:startline)

  " get first non-blank line above our startline that comes after a non-comment line
  let realstartline = a:startline - 1
  while realstartline > 0
    let line = getline(realstartline)
    if line !~ s:regex_blank_line && line !~ s:regex_comment
      break
    endif
    let realstartline = realstartline - 1
  endwhile
  let realstartline = realstartline + 1
  while getline(realstartline) =~ s:regex_blank_line
    let realstartline = realstartline + 1
  endwhile

  " now get end of fold
  while endline <= last_linenum
    let line = getline(endline)
    if s:regex_end == ''
      if indent(endline) <= startindent && line !~ s:regex_blank_line
        break
      endif
    elseif indent(endline) <= startindent && line =~ s:regex_end
      break
    endif
    let endline = endline + 1
  endwhile
  if endline <= last_linenum && s:regex_end == ''
    let endline = endline - 1
  endif

  if endline <= last_linenum
    " add any trailing blank lines
    let endline = endline + 1
    while endline <= last_linenum && getline(endline) =~ s:regex_blank_line
      let endline = endline + 1
    endwhile
    let endline = endline - 1

    "echo 'Going to create fold from ' . realstartline . ' to ' . endline
    execute realstartline . ',' . endline . ' fold'
  endif

  return endline + 1
endfunction

" user facing stuff
if !hasmapto("<Plug>Collapse_CollapseAll")
  map <unique> <silent> <Leader>9 <Plug>Collapse_CollapseAll
endif
noremap <unique> <script> <Plug>Collapse_CollapseAll <SID>CollapseAll
noremap <SID>CollapseAll :call <SID>CollapseAll()<cr>
if !exists(':CollapseAll')
  command -nargs=0 CollapseAll :call s:CollapseAll()
endif
if !exists(':CollapseSetRegexs')
  command -nargs=+ CollapseSetRegexs :call Collapse_SetRegexs(<f-args>)
endif

" restore compatible mode
let &cpo = s:save_cpo
