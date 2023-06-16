require_relative '../completion_entry'

module Juggler::Plugins
  class Cscope < Base
    def initialize(options)
      @cscope_service = Juggler::CscopeService.new(File.join(Juggler::Completer.instance.indexes_path, 'cscope.out'))
    end

    def show_references(_path, _line, _col, term)
      @cscope_service.query(term, Juggler::CscopeQuery::Symbol)
    end

    def generate_completions(_absolute_path, base, cursor_info)
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
