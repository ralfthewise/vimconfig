module Juggler::Plugins
  class GrepAg < Base
    def grep(srchstr)
      grep_cmd = 'ag --nogroup --nocolor --vimgrep --hidden'
      strip_tabs_cmd = "sed 's/\\t/  /g'" #sometimes cexpr and cgetexpr have issues with tabs
      if srchstr.start_with?('/')
        srchstr = srchstr[1..-1] #strip off beginning '/'
        grep_cmd += ' --case-sensitive'
      else
        srchstr = srchstr[1..-1] if srchstr.start_with?('\/') #strip off beginning '\'
        grep_cmd += ' --smart-case --literal'
      end
      grep_cmd = "#{grep_cmd} -- #{Shellwords.escape(srchstr)} ."

      start = Time.now
      result = `#{grep_cmd} | #{strip_tabs_cmd}`
      logger.debug { "#{self.class.to_s} grep took #{Time.now - start} seconds: #{grep_cmd}\n  Result:\n#{result}" }
      result = result.gsub("\r\n", "\n").gsub("\r", "\n")
      Juggler.clean_utf8(result).split("\n")
    end
  end
end
