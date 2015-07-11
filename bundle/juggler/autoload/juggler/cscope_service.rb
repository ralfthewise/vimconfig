module Juggler
  class CscopeService
    #example match from cscope line-oriented-interface:
    #/home/tim/dev/idexperts/api/src/github.com/radartools/api/cmd/api/tokens.go <unknown> 27        r.Get(api.TokensPostRoute).HandlerFunc(m.tokensPost)
    @@cscope_line_regexp = /^(\S+)\s(\S+)\s(\d+)\s+(.+)$/

    def initialize(cscope_db)
      @cscope_db = cscope_db
      init_cscope_connection
    end

    def query(pattern)
      result = []
      IO.popen("cscope -dC -L -f'#{@cscope_db}' -6'#{pattern}'", 'w+') do |sp|
        sp.read.split("\n").each_with_index do |line,index|
          if match = @@cscope_line_regexp.match(line)
            result << {index: index, file: match[1], kind: match[2], line: match[3], tag_line: match[4]}
          end
        end
      end
      return result
    end

    protected
    def init_cscope_connection
      return

      #TODO: in the future we might want to use the line-oriented-interface of cscope:
      #IO.popen('cscope -d -C -l', 'w+') do |sp|
      #  puts sp.readpartial(1024);
      #  sp.write("6.*token.*\n");
      #  puts sp.readpartial(1024)
      #end
    end
  end
end
