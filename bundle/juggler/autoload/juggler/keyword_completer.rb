require_relative 'completion_entry'

module Juggler
  class KeywordCompleter
    #example line:
    # 17:   31 type PublicIncident struct {
    @@keyword_regexp = /^\s*(\d+):\s+(\d+)\s+(.+)$/

    def generate_completions(base)
      return if base.nil? || base.empty?

      base_regex = Regexp.new(Juggler.generate_scan_base_pattern(base), Regexp::IGNORECASE)
      keyword_output = VIM::evaluate("s:GetKeywords('/\\c#{Juggler.escape_vim_singlequote_string(generate_keyword_pattern(base))}')")
      keyword_output.split("\n").each do |line|
        if match = @@keyword_regexp.match(line)
          index = match[1].to_i
          line_num = match[2].to_i
          match[3].scan(base_regex) do |tag|
            entry = CompletionEntry.new(source: :keyword, index: index, line: line_num, tag: tag)
            yield(entry)
          end
        end
      end
    end

    protected
    def generate_keyword_pattern(base)
      return base.scan(/./).join('.*')
    end
  end
end
