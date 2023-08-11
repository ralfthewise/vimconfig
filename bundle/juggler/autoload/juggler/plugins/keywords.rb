require_relative '../completion_entry'

module Juggler::Plugins
  class Keywords < Base
    # example lines:
    # app/search-scoop/services/card-display-state.coffee
    #   17:   31 type PublicIncident struct {
    @keyword_regexp = /^\s*(\d+):\s+(\d+)\s+(.+)$/

    class << self; attr_reader :keyword_regexp; end

    def initialize(project_dir:, **opts)
      super
      @project_dir = File.absolute_path(project_dir)
    end

    def generate_completions(_absolute_path, base, _cursor_info)
      return if base.nil? || base.empty?

      file = nil
      should_include_file = false
      base_regex = Regexp.new(generate_keyword_match_pattern(base), Regexp::IGNORECASE)
      pattern = Juggler.escape_vim_singlequote_string(generate_keyword_search_pattern(base))
      logger.debug {"Performing keywords search for: #{pattern}"}
      logger.debug {"Current dir is: #{Dir.getwd}"}
      keyword_output = VIM::evaluate("s:GetKeywords('#{pattern}')")
      logger.debug {"Keywords search output: #{keyword_output}"}
      keyword_output.split("\n").each do |line|
        if (match = self.class.keyword_regexp.match(line))
          # Doing `VIM::command("exe 'ilist! <some pattern>'")` from within a
          # plugin's ruby file in vim sometimes returns results from random
          # ruby library files (such as
          # /usr/local/rbenv/versions/3.0.2/lib/ruby/3.0.0/x86_64-linux/socket.so)
          # so we limit the results to files that are somewhere within the
          # project_dir
          next unless should_include_file

          index = match[1].to_i
          line_num = match[2].to_i
          match[3].scan(base_regex) do |m|
            entry = Juggler::CompletionEntry.new(source: :keyword, index: index, file: file, line: line_num, tag: m.last)
            yield(entry)
          end
        else
          file = File.absolute_path(line)
          should_include_file = file.start_with?(@project_dir)
        end
      end
    end

    protected

    # This regexp is passed to vim's `ilist!`
    def generate_keyword_search_pattern(base)
      # '\c' makes it case insensitive

      # This pattern requires the keyword start with the first letter in `base`
      return "/\\c\\(^\\|\\W\\)#{base.scan(/./).join('\w*')}"

      # This pattern allows there to be preceeding letters in front of the first letter of `base`
      # return "/\\c#{base.scan(/./).join('\w*')}"
    end

    # This regexp is used to parse/tokenize each line of the output from `ilist!`
    def generate_keyword_match_pattern(base)
      # Again, must start with the first letter of `base`
      return "(^|\\W+)(#{base.scan(/./).join('\w*')}\\w*)"

      # Allows preceeding letters in front of the first letter of `base`
      # return "(\\w*#{base.scan(/./).join('\w*')}\\w*)"
    end
  end
end
