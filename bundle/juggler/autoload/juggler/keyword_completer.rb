require_relative 'completion_entry'

module Juggler
  class KeywordCompleter
    #example lines:
    #app/search-scoop/services/card-display-state.coffee
    # 17:   31 type PublicIncident struct {
    @@keyword_regexp = /^\s*(\d+):\s+(\d+)\s+(.+)$/

    def generate_completions(base)
      return if base.nil? || base.empty?

      file = nil
      base_regex = Regexp.new(generate_keyword_match_pattern(base), Regexp::IGNORECASE)
      keyword_output = VIM::evaluate("s:GetKeywords('#{Juggler.escape_vim_singlequote_string(generate_keyword_search_pattern(base))}')")
      keyword_output.split("\n").each do |line|
        if match = @@keyword_regexp.match(line)
          index = match[1].to_i
          line_num = match[2].to_i
          match[3].scan(base_regex) do |tag|
            entry = CompletionEntry.new(source: :keyword, index: index, file: file, line: line_num, tag: tag)
            yield(entry)
          end
        else
          file = File.expand_path(line)
        end
      end
    end

    protected
    def generate_keyword_search_pattern(base)
      #'\c' makes it case insensitive
      return '/\\c' + base.scan(/./).join('\w*')
    end

    def generate_keyword_match_pattern(base)
      return '\w*' + base.scan(/./).join('\w*') + '\w*'
    end
  end
end
