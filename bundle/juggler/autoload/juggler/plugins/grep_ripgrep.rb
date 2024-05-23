module Juggler::Plugins
  class GrepRipgrep < Base
    def grep(srchstr)
      grep_cmd = "rg --color never --vimgrep --hidden --glob '!.git' --follow"
      strip_tabs_cmd = "sed 's/\\t/  /g'" # sometimes cexpr and cgetexpr have issues with tabs
      if srchstr.start_with?('/')
        srchstr = srchstr[1..-1] # strip off beginning '/'
        grep_cmd += ' --case-sensitive'
      else
        srchstr = srchstr[1..-1] if srchstr.start_with?('\/') # strip off beginning '\'
        grep_cmd += ' --ignore-case'
      end
      grep_cmd = "#{grep_cmd} -- #{Shellwords.escape(srchstr)}"

      start = Time.now
      result = `#{grep_cmd} | #{strip_tabs_cmd}`
      logger.debug { "grep took #{Time.now - start} seconds: #{grep_cmd}\n  Result:\n#{result}" }
      result = result.gsub("\r\n", "\n").gsub("\r", "\n")
      Juggler.clean_utf8(result).split("\n")
    end

    def find_files(srchstr)
      return [] if srchstr.nil? || srchstr.empty?

      # search_regex = Regexp.new('\w*' + str.scan(/./).join('\w*') + '\w*', Regexp::IGNORECASE)
      search_regex = srchstr.scan(/./).join('.*')
      grep_cmd = "rg --files | rg --ignore-case -- #{Shellwords.escape(search_regex)}"
      logger.debug { "Searching for files with command: #{grep_cmd}" }
      `#{grep_cmd}`.split("\n").map(&:strip)


      # Can do the below to get indexes of matches
      # re = /^\/\^(.+)\$\/$/
      # m = re.match('/^  foo()$/')
      # m.begin(1)
      # m.end(1)

      # Things to consider for weights
      #   * letters next to each other
      #   * letters immediately after a break (ie _, /, -, ., etc)
      #   * file basename match
      #   * capital letter after lowercase letter
    end
  end
end
