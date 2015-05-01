require_relative 'completion_entry'

module Juggler
  class CtagsCompleter
    @@ctag_line1_regexp = /^>?\s+(\d+)\s+([FSC]*)\s+(\w)\s+(\S+)\s+(\S+)$/
    @@ctag_info_line_regexp = /([^:\s]+:[^:]+)(\s|$)/
    @@digit_regexp = /^\d+$/

    def generate_completions(base)
      ctag_output = VIM::evaluate("s:GetTags('/#{Juggler.escape_vim_singlequote_string(base)}')")
      entry = nil
      ctag_output.split("\n").each do |line|
        if entry.nil?
          if match = @@ctag_line1_regexp.match(line)
            entry = CompletionEntry.new(source: :ctags, index: match[1], pri: match[2], kind: match[3], tag: match[4], file: match[5])
          end
        else
          info_match = line.scan(@@ctag_info_line_regexp).map {|m| m.first}
          if !info_match.empty?
            entry.info = line.strip
            info_match.each do |info|
              info_pair = info.split(':')
              case info_pair[0]
              when 'signature' then entry.signature = info_pair[1]
              when 'line' then entry.line = info_pair[1].to_i
              end
            end
          else
            entry.excmd = line.strip
            entry.line = entry.excmd.to_i if @@digit_regexp.match(entry.excmd)
            yield(entry)
            entry = nil
          end
        end
      end
      yield(entry) unless entry.nil?
    end
  end
end
