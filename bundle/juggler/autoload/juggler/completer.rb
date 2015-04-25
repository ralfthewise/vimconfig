require 'singleton'
require_relative 'completion_entry'
require_relative 'entry_scorer'
require_relative 'completion_entries'

module Juggler
  class Completer
    include Singleton

    @@ctag_line1_regexp = /^>?\s+(\d+)\s+([FSC]*)\s+(\w)\s+(\S+)\s+(\S+)$/
    @@ctag_info_line_regexp = /([^:\s]+:[^:]+)(\s|$)/
    @@digit_regexp = /^\d+$/

    def generate_completions
      base = VIM::evaluate('a:base')
      scorer = EntryScorer.new(base)
      entries = CompletionEntries.new

      ctag_output = VIM::evaluate("s:GetTags('/#{Juggler.escape_vim_singlequote_string(base)}')")
      entry = nil
      ctag_output.split("\n").each do |line|
        if entry.nil?
          if match = @@ctag_line1_regexp.match(line)
            entry = CompletionEntry.new(index: match[1], pri: match[2], kind: match[3], tag: match[4], file: match[5])
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
            entry.score = scorer.score(entry)
            entries.push(entry)
            entry = nil
          end
        end
      end

      entries.process do |vim_arr|
        VIM::command("call extend(s:juggler_completions, [#{vim_arr}])")
      end
    end
  end
end
