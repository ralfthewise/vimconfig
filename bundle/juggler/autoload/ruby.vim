" language support depends on vim-textobj-user
if !exists('*textobj#user#plugin') | finish | endif

"add ruby text objects so vim-expand-region works on ruby files
"blatantly taken from https://github.com/vim-ruby/vim-ruby

" Regex of syntax group names that are or delimit strings/symbols or are comments.
let s:ruby_syng_strcom = '\<ruby\%(Regexp\|RegexpDelimiter\|RegexpEscape' .
      \ '\|Symbol\|String\|StringDelimiter\|StringEscape\|ASCIICode' .
      \ '\|Interpolation\|InterpolationDelimiter\|NoInterpolation\|Comment\|Documentation\)\>'

" Expression used to check whether we should skip a match with searchpair().
let s:ruby_skip_expr =
      \ "synIDattr(synID(line('.'),col('.'),1),'name') =~ '".s:ruby_syng_strcom."'"

" Regex that defines the start-match for the 'end' keyword.
"let s:end_start_regex = '\%(^\|[^.]\)\<\%(module\|class\|def\|if\|for\|while\|until\|case\|unless\|begin\|do\)\>'
" TODO: the do here should be restricted somewhat (only at end of line)?
let s:ruby_end_start_regex =
      \ '\C\%(^\s*\|[=,*/%+\-|;{]\|<<\|>>\|:\s\)\s*\zs' .
      \ '\<\%(module\|class\|if\|for\|while\|until\|case\|unless\|begin' .
      \   '\|\%(public\|protected\|private\)\=\s*def\):\@!\>' .
      \ '\|\%(^\|[^.:@$]\)\@<=\<do:\@!\>'

" Regex that defines the middle-match for the 'end' keyword.
let s:ruby_end_middle_regex = '\<\%(ensure\|else\|\%(\%(^\|;\)\s*\)\@<=\<rescue:\@!\>\|when\|elsif\):\@!\>'

" Regex that defines the end-match for the 'end' keyword.
let s:ruby_end_end_regex = '\%(^\|[^.:@$]\)\@<=\<end:\@!\>'

" Expression used for searchpair() call for finding match for 'end' keyword.
let s:ruby_end_skip_expr = s:ruby_skip_expr .
      \ ' || (expand("<cword>") == "do"' .
      \ ' && getline(".") =~ "^\\s*\\<\\(while\\|until\\|for\\):\\@!\\>")'

"let s:ruby_textobj_comment_escape = '\v^[^#]*'
"let s:ruby_textobj_start_pattern = s:ruby_textobj_comment_escape . '\zs(<def>|<if>|<do>|<module>|<class>)'
"let s:ruby_textobj_end_pattern = s:ruby_textobj_comment_escape . '\zs<end>'
"let s:ruby_textobj_skip_pattern = 'getline(".") =~ "\\v\\S\\s<(if|unless)>\\s\\S"'

"call textobj#user#plugin('juggler', {
"      \      '-': {
"      \        'sfile': expand('<sfile>'),
"      \        'ruby-select-a-function': 's:ruby_select_a', 'ruby-select-a': 'ar',
"      \        'ruby-select-i-function': 's:ruby_select_i', 'ruby-select-i': 'ir'
"      \      }
"      \    })
call textobj#user#plugin('juggler', {
      \      '-': {
      \        'sfile': expand('<sfile>'),
      \        'select-a-function': 's:ruby_select_a', 'select-a': 'ar',
      \        'select-i-function': 's:ruby_select_i', 'select-i': 'ir'
      \      }
      \    })

function! s:ruby_select_a()
  for _ in range(v:count1)
    call searchpair(s:ruby_end_start_regex, s:ruby_end_middle_regex, s:ruby_end_end_regex, 'W', s:ruby_end_skip_expr)
  endfor
  "call searchpair(s:ruby_textobj_start_pattern,'',s:ruby_textobj_end_pattern, 'W', s:ruby_textobj_skip_pattern)
  let end_pos = getpos('.')

  " Jump to match
  normal %
  let start_pos = getpos('.')

  return ['V', start_pos, end_pos]
endfunction

function! s:ruby_select_i()
  let flags = 'W'
  if expand('<cword>') == 'end'
    let flags = 'cW'
  endif

  for _ in range(v:count1)
    call searchpair(s:ruby_end_start_regex, s:ruby_end_middle_regex, s:ruby_end_end_regex, flags, s:ruby_end_skip_expr)
  endfor

  "call searchpair(s:ruby_textobj_start_pattern,'',s:ruby_textobj_end_pattern, flags, s:ruby_textobj_skip_pattern)

  " Move up one line, and save position
  normal k^
  let end_pos = getpos('.')

  " Move down again, jump to match, then down one line and save position
  normal j^%j
  let start_pos = getpos('.')

  return ['V', start_pos, end_pos]
endfunction
