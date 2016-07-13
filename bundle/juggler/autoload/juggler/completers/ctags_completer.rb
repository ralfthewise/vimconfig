require_relative '../completion_entry'

module Juggler::Completers
  class CtagsCompleter
    #example result from taglist():
    #
    #  [{'cmd': '/^  appendValAtPath = (dataModel, modelPath, modelVal, archetypeProperties) ->$/', 'static': 0, 'name': 'appendValAtPath', 'line': '6', 'language': 'coffee', 'kind': 'function', 'filename': './app/components/radar-forms/services/form-data-translator.coffee'}]

    def generate_completions(base, cursor_info)
      return if base.nil? || base.empty?

      ctag_output = VIM::evaluate("s:GetTags('\\c#{Juggler.escape_vim_singlequote_string(generate_ctag_pattern(base))}')")
      ctag_output.each_with_index do |ctag_entry, index|
        line_num = ctag_entry['line']
        line_num = line_num.to_i unless line_num.nil?
        entry = Juggler::CompletionEntry.new(source: :ctags, index: index, kind: ctag_entry['kind'], tag: ctag_entry['name'], file: ctag_entry['filename'], line: line_num)
        entry.excmd = ctag_entry['cmd']
        yield(entry)
      end
    end

    protected
    def generate_ctag_pattern(base)
      return base.scan(/./).join('.*')
    end
  end
end
