require_relative 'completion_entry'

module Juggler
  class CscopeCompleter
    #columns are:
    #  #   line  filename / context / line

    #example match:
    #  1     22  autoload/juggler/completer.rb <<<unknown>>>
    #                  scorer = EntryScorer.new(cursor_info['token'])
    @@cscope_line1_regexp = /^\s*(\d+)\s+(\d+)\s+(.+)$/

    def generate_completions(base)
      return if base.nil? || base.empty?

      base_regex = Regexp.new(Juggler.generate_scan_base_pattern(base), Regexp::IGNORECASE)
      cscope_output = VIM::evaluate("s:GetCscope('#{Juggler.escape_vim_singlequote_string(base)}')")
      entry = nil
      cscope_output.split("\n").each do |line|
        if entry.nil?
          if match = @@cscope_line1_regexp.match(line)
            entry = CompletionEntry.new(source: :cscope, index: match[1], line: match[2].to_i)
          end
        else
          line.scan(base_regex) do |tag|
            entry.tag = tag
          end
          yield(entry)
          entry = nil
        end
      end
    end
  end
end
