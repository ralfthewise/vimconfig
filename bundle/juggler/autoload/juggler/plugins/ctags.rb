require_relative '../completion_entry'

module Juggler::Plugins
  class Ctags < Base
    #example result from taglist():
    #
    #  [{'cmd': '/^  appendValAtPath = (dataModel, modelPath, modelVal, archetypeProperties) ->$/', 'static': 0, 'name': 'appendValAtPath', 'line': '6', 'language': 'coffee', 'kind': 'function', 'filename': './app/components/radar-forms/services/form-data-translator.coffee'}]
    @cmd_regexp = /^\/\^(.+)\$\/$/
    class << self; attr_reader :cmd_regexp; end

    def initialize(project_dir:, **opts)
      super
      @indexes_path = Juggler::Completer.instance.indexes_path
    end

    def generate_completions(_absolute_path, base, cursor_info)
      return if base.nil? || base.empty? || cursor_info['token'].length < 2

      ctag_output = VIM::evaluate("s:GetTags('\\c#{Juggler.escape_vim_singlequote_string(generate_ctag_pattern(base))}')")
      ctag_output.each_with_index do |ctag_entry, index|
        line_num = ctag_entry['line']
        line_num = line_num.to_i unless line_num.nil?
        entry = Juggler::CompletionEntry.new(source: :ctags, index: index, kind: ctag_entry['kind'], tag: ctag_entry['name'], file: ctag_entry['filename'], line: line_num)
        entry.excmd = ctag_entry['cmd']
        yield(entry)
      end
    end

    # Should return an array of Juggler::LocationEntrys
    def go_to_definition(_cursor_info, term)
      ctag_output = VIM::evaluate("s:GetTags('^#{Juggler.escape_vim_singlequote_string(term)}$')")
      ctag_output.map do |ctag_entry|
        desc = ctag_entry['name']
        if (match = self.class.cmd_regexp.match(ctag_entry['cmd']))
          desc = match[1].strip
        end
        Juggler::LocationEntry.new(source: :ctags, file: ctag_entry['filename'], line: ctag_entry['line'], description: desc)
      end
    end

    def find_tags(cursor_info, srchstr)
      result = Juggler::LocationEntryCollection.new(cursor_info, srchstr)
      return result if srchstr.nil? || srchstr.empty?

      # ctag_output = VIM::evaluate("s:GetTags('^#{Juggler.escape_vim_singlequote_string(srchstr)}$')")
      ctag_output = VIM::evaluate("s:GetTags('\\c#{Juggler.escape_vim_singlequote_string(generate_ctag_pattern(srchstr))}')")
      ctag_output.each do |ctag_entry|
        desc = ctag_entry['name']
        # if (match = self.class.cmd_regexp.match(ctag_entry['cmd']))
        #   desc = match[1].strip
        # end
        result << Juggler::LocationEntry.new(source: :ctags, file: ctag_entry['filename'], line: ctag_entry['line'], description: desc)
      end
      result
    end

    def update_indexes(only_current_file: false)
      dest_file = File.join(@indexes_path, 'tags.files')
      escaped_indexes_path = Shellwords.escape(@indexes_path)
      escaped_dest_file = Shellwords.escape(dest_file)

      only_current_file = false if !File.exist?(dest_file)
      FileUtils.rm(Dir.glob(File.join(@indexes_path, 'tags*'))) if !only_current_file

      cmd = if only_current_file
              absolute_path = File.expand_path($curbuf.name)
              "cd #{escaped_indexes_path} && echo #{Shellwords.escape(absolute_path)} | ctags --append --fields=afmikKlnsStz --sort=foldcase -L - -f tags > /dev/null 2>&1"
            else
              # If you `rm` a file but don't `git rm` it, then the `git
              # ls-files ...` command below will still print that file, which
              # is why we have to `2> /dev/null` the `xargs ...` command
              dest_file_cmd = "git ls-files -z --cached --others --exclude-standard | xargs --null grep -Il --null . 2> /dev/null | xargs --null readlink -e > #{escaped_dest_file}"
              "#{dest_file_cmd} && cd #{escaped_indexes_path} && ctags --fields=afmikKlnsStz --sort=foldcase -L tags.files -f tags > /dev/null 2>&1"
            end

      Juggler.logger.debug {"Updating ctags with the following command: #{cmd}"}
      start = Time.now
      if system(cmd)
        Juggler.logger.info {"Updating ctags took #{Time.now - start} seconds"}
      else
        Juggler.logger.error {"Error updating ctags with the following command: #{cmd}"}
      end
    end

    protected

    def generate_ctag_pattern(base)
      return base.scan(/./).join('.*')
    end
  end
end
