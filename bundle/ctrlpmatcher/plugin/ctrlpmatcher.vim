" CtrlP plugin for better matching
" Last Change:  2012 Nov 26
" Maintainer: Tim Garton <tim@datastarved.net>
" License:

" only load once
if ( exists('g:loaded_ctrlpmatcher') && g:loaded_ctrlpmatcher ) || v:version < 700 || &cp
  finish
endif
let g:loaded_ctrlpmatcher = 1

if !exists('g:ctrlpmatcher_debug')
  let g:ctrlpmatcher_debug = 0
endif

" avoid issues with compatible mode
let s:save_cpo = &cpo
set cpo&vim

let g:ctrlpmatcher_split_chars = '_A-Z'

function! ctrlpmatcher#MatchIt(items, str, limit, mmode, ispath, crfile, regex)
  let results = []

  ruby << EOF
    items = VIM::evaluate('a:items')
    str = VIM::evaluate('a:str')
    limit = VIM::evaluate('a:limit').to_i
    mmode = VIM::evaluate('a:mmode')
    regex = VIM::evaluate('a:regex')
    ctrlpmatcher_log("MatchIt called - str: #{str}, limit: #{limit}, mmode: #{mmode}, regex: #{regex}")
    ctrlpmatcher_log("  Split regex: #{split_regex}")

    if str.nil? || str.empty?
      items.each {|item| VIM::evaluate("add(results, '#{item.gsub("'", "''")}')")}
    else
      results = {}
      regexs = []

      # consider search str 'ConD' and split chars of '_A-Z'

      #first break it into pieces
      pattern_pieces = str.to_s.scan(split_regex) #['Con', 'D']
      pattern_pieces.delete('')
      ctrlpmatcher_log("  Pattern Pieces are: #{pattern_pieces}")

      #^ConD
      regex_str = "^#{str}"
      ctrlpmatcher_add_regex(results, regexs, regex_str)

      #^Con[^_A-Z]*D
      regex_str = "^#{pattern_pieces.join("[^#{split_chars}]*")}"
      ctrlpmatcher_add_regex(results, regexs, regex_str)

      #^Con.*D
      regex_str = "^#{pattern_pieces.join(".*")}"
      ctrlpmatcher_add_regex(results, regexs, regex_str)

      #ConD
      regex_str = str
      ctrlpmatcher_add_regex(results, regexs, regex_str)

      #Con[^_A-Z]*D
      regex_str = "#{pattern_pieces.join("[^#{split_chars}]*")}"
      ctrlpmatcher_add_regex(results, regexs, regex_str)

      #Con.*D
      regex_str = "#{pattern_pieces.join(".*")}"
      ctrlpmatcher_add_regex(results, regexs, regex_str)

      #C.*o.*n.*D
      regex_str = str.chars.to_a.join('.*')
      ctrlpmatcher_add_regex(results, regexs, regex_str)

      #c.*o.*n.*d
      regex_str = str.downcase.chars.to_a.join('.*')
      ctrlpmatcher_add_regex(results, regexs, regex_str)

      #find our actual matches
      count = 0
      items.each do |item|
        search_part = (mmode == 'first-non-tab' ? item.split("\t")[0] : item)
        regexs.each_with_index do |regex, i|
          if search_part.match(results[regex][:regex])
            results[regex][:items] << item
            count += 1 if i == 0
            break
          end
        end
        break if count >= limit
      end

      #store the results
      regexs.each do |regex|
        results[regex][:items].each do |item|
          cleaned_item = item.gsub("'", "''")
          VIM::evaluate("add(results, '#{cleaned_item}')")
        end
      end
    end
EOF

  return results
endfunction

ruby << EOF
  split_chars = VIM::evaluate('g:ctrlpmatcher_split_chars')
  split_regex = Regexp.new("[#{split_chars}]?[^#{split_chars}]*")

  def ctrlpmatcher_log(msg)
    debug = VIM::evaluate('g:ctrlpmatcher_debug')
    File.open('/tmp/vim.log', 'a') {|f| f.puts(msg)} if debug.to_s == '1'
  end

  def ctrlpmatcher_add_regex(results, regexs, regex_str)
    unless results.has_key? regex_str
      ctrlpmatcher_log("  Next regexp pattern: #{regex_str}")
      regexs << regex_str
      results[regex_str] = {:regex => Regexp.new(regex_str), :items => []}
    end
  end
EOF

" restore compatible mode
let &cpo = s:save_cpo
