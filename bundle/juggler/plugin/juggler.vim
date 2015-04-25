if exists('g:juggler_loaded')
  finish
endif
let g:juggler_loaded = 1

function s:defineOption(name, default)
  if !exists(a:name)
    let {a:name} = a:default
  endif
endfunction

call s:defineOption('g:juggler_fixupPopupMenu', 1)

if g:juggler_fixupPopupMenu
endif
