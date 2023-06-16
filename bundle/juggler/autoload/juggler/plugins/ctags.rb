require_relative '../completion_entry'

module Juggler::Plugins
  class Ctags < Base
    #example result from taglist():
    #
    #  [{'cmd': '/^  appendValAtPath = (dataModel, modelPath, modelVal, archetypeProperties) ->$/', 'static': 0, 'name': 'appendValAtPath', 'line': '6', 'language': 'coffee', 'kind': 'function', 'filename': './app/components/radar-forms/services/form-data-translator.coffee'}]

    def initialize(project_dir:, **opts)
      super

      init_indexes(project_dir)
    end

    def generate_completions(_absolute_path, base, cursor_info)
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

    def init_indexes(project_dir)
      return if project_dir.nil?

      digest = Digest::SHA1.hexdigest(project_dir)
      indexes_path = File.join(Dir.home, '.vim_indexes', digest)
      FileUtils.mkdir_p(indexes_path)
      VIM::command("let s:indexespath = '#{Juggler.escape_vim_singlequote_string(indexes_path)}'")
      VIM::command("execute 'set tags=#{Juggler.escape_vim_singlequote_string(indexes_path)}/tags'")
    end
  end
end
