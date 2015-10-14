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
      pattern = generate_cscope_pattern(pattern)

      result = []
      IO.popen("cscope -dC -L -f'#{@cscope_db}' -6'#{pattern}'", 'w+') do |sp|
        Juggler.clean_utf8(sp.read).split("\n").each_with_index do |line,index|
          if match = @@cscope_line_regexp.match(line)
            kind = (match[2] == '<unknown>' ? nil : match[2])
            result << {index: index, file: match[1], kind: kind, line: match[3].to_i, tag_line: match[4]}
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

    #cscope egrep is pretty bad - very few character classes
    def generate_cscope_pattern(base)
      return "^(.* )?#{base}" if base.length <= 2
      return "^(.* )?#{base}"
      #return '^(.* )?p[a-zA-Z0-9]*a'
    end
  end
end
