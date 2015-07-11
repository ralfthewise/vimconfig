require_relative 'completion_entry'

module Juggler
  class CscopeCompleter
    def initialize(cscope_service)
      @cscope_service = cscope_service
    end

    def generate_completions(base)
      return if base.nil? || base.empty?

      base_regex = Regexp.new(Juggler.generate_scan_base_pattern(base), Regexp::IGNORECASE)
      @cscope_service.query(base).each do |cscope_entry|
        entry = CompletionEntry.new(source: :cscope, index: cscope_entry[:index], line: cscope_entry[:line], kind: cscope_entry[:kind], signature: cscope_entry[:tag_line].strip)
        cscope_entry[:tag_line].scan(base_regex) do |tag|
          entry.tag = tag
        end
        yield(entry)
      end
    end
  end
end
