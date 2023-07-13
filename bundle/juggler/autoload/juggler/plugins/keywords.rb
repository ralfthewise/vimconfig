require_relative '../completion_entry'

module Juggler::Plugins
  class Keywords < Base
    #example lines:
    #app/search-scoop/services/card-display-state.coffee
    # 17:   31 type PublicIncident struct {
    @@keyword_regexp = /^\s*(\d+):\s+(\d+)\s+(.+)$/

    def initialize(project_dir:, current_file:, cmd: nil, host: nil, port: 7658, **opts)
      super
      @project_dir = File.absolute_path(project_dir)
    end

    def generate_completions(_absolute_path, base, cursor_info)
      return if base.nil? || base.empty?

      file = nil
      should_include_file = false
      base_regex = Regexp.new(generate_keyword_match_pattern(base), Regexp::IGNORECASE)
      pattern = Juggler.escape_vim_singlequote_string(generate_keyword_search_pattern(base))
      logger.debug { "Performing keywords search for: #{pattern}" }
      logger.debug { "Current dir is: #{Dir.getwd}" }
      keyword_output = VIM::evaluate("s:GetKeywords('#{pattern}')")
      logger.debug { "Keywords search output: #{keyword_output}" }
      keyword_output.split("\n").each do |line|
        if match = @@keyword_regexp.match(line)
          # Doing `exe 'ilist! <some pattern>'` from within a ruby file in vim
          # sometimes returns results from random ruby files (such as
          # /usr/local/rbenv/versions/3.0.2/lib/ruby/3.0.0/x86_64-linux/socket.so)
          # so we limit the results to files that are somewhere within the
          # project_dir
          next unless should_include_file

          index = match[1].to_i
          line_num = match[2].to_i
          match[3].scan(base_regex) do |tag|
            entry = Juggler::CompletionEntry.new(source: :keyword, index: index, file: file, line: line_num, tag: tag)
            yield(entry)
          end
        else
          file = File.absolute_path(line)
          should_include_file = @project_dir.start_with?(file)
        end
      end
    end

    protected
    def generate_keyword_search_pattern(base)
      #'\c' makes it case insensitive
      return '/\\c' + base.scan(/./).join('\w*')
    end

    def generate_keyword_match_pattern(base)
      return '\w*' + base.scan(/./).join('\w*') + '\w*'
    end
  end
end
