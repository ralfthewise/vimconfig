require_relative '../completion_entry'

module Juggler::Completers
  class CscopeCompleter
    def initialize(cscope_service)
      @cscope_service = cscope_service
    end

    def generate_completions(base)
      return if base.nil? || base.empty?

      #BUG this regex below doesn't grab the right tag from the cscope results
      base_regex = Regexp.new(Juggler.generate_scan_base_pattern(base), Regexp::IGNORECASE)
      @cscope_service.query(base, Juggler::CscopeQuery::Egrep).each do |cscope_entry|
        entry = Juggler::CompletionEntry.new(source: :cscope, index: cscope_entry[:index], line: cscope_entry[:line], file: cscope_entry[:file], kind: cscope_entry[:kind], signature: cscope_entry[:tag_line].strip)
        cscope_entry[:tag_line].scan(base_regex) do |tag|
          entry.tag = tag
        end
        yield(entry)
      end
    end
  end
end
