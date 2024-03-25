require_relative '../completion_entry'

module Juggler::Plugins
  class Cscope < Base
    def initialize(_options)
      @indexes_path = Juggler::Completer.instance.indexes_path
      @cscope_service = Juggler::CscopeService.new(File.join(@indexes_path, 'cscope.out'))
    end

    def show_references(_path, _line, _col, term)
      @cscope_service.query(term, Juggler::CscopeQuery::Symbol)
    end

    def generate_completions(_absolute_path, base, cursor_info)
      return if base.nil? || base.empty? || cursor_info['token'].length < 2

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

    # Should return an array of objects with the following properties:
    #   file: path to file (relative to project root)
    #   line: line in the file (starting from 1, not 0)
    #   col: column of the line (starting from 1, not 0)
    #   desc: description to display
    def go_to_definition(_path, _line, _col, term)
      @cscope_service.query(term, Juggler::CscopeQuery::Symbol).map do |cscope_entry|
        col = cscope_entry[:tag_line].index(Regexp.new(term, Regexp::IGNORECASE)).to_i + 1 # This isn't quite right because cscope strips off leading spaces
        {file: cscope_entry[:file], line: cscope_entry[:line], col: col, desc: cscope_entry[:tag_line].strip}
      end
    end

    def update_indexes(only_current_file: false)
      dest_file = File.join(@indexes_path, 'cscope.files')
      escaped_indexes_path = Shellwords.escape(@indexes_path)
      escaped_dest_file = Shellwords.escape(dest_file)

      only_current_file = false if !File.exist?(dest_file)
      FileUtils.rm(Dir.glob(File.join(@indexes_path, 'cscope.*'))) if !only_current_file

      # cscope can't handle paths that include a space (https://sourceforge.net/p/cscope/bugs/200/#10cf) - hence the `| grep -v ' '` below.
      # if you include a path that has a space and then run a query that matches in that file, cscope just outputs:
      #   File does not have expected format
      # if they ever fix it to handle spaces in filenames, you might have to pipe it to some sed magic like so:
      #   | sed 's/^\\(.*[ \\t].*\\)$/\"\\1\"/'"
      # the `xargs --null grep -Il --null .` below makes sure we don't include binary files
      # the `xargs --null readlink -e` below makes sure we get the absolute path of each file
      dest_file_cmd = "git ls-files -z --cached --others --exclude-standard | xargs --null grep -Il --null . | xargs --null readlink -e | grep -v ' ' > #{escaped_dest_file}"
      cmd = "cd #{escaped_indexes_path} && cscope -q -b -U > /dev/null 2>&1"
      cmd = "#{dest_file_cmd} && #{cmd}" if !only_current_file

      Juggler.logger.debug {"Updating cscope with the following command: #{cmd}"}
      Juggler.refresh
      start = Time.now
      if system(cmd)
        Juggler.logger.info {"Updating cscope took #{Time.now - start} seconds"}
        Juggler.refresh
      else
        Juggler.logger.error {"Error updating cscope with the following command: #{cmd}"}
      end
    end
  end
end
