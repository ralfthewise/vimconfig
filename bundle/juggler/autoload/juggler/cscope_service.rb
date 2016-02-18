module Juggler
  class CscopeQuery
    Symbol=0 #references to symbols/types/funcs/etc matching the query param
    Definition=1 #definition of symbols/types/funcs/etc matching the query param
    Called=2 #functions called by the function matching the query param
    Callers=3 #functions that call the function matching the query param
    Text=4 #any text matching the query param
    Egrep=6 #any text matching the query param and treating the query param as an egrep expression
    File=7 #file matching the query param
    IncludedBy=8 #files including the file matching the query param
  end

  class CscopeService
    #example match from cscope line-oriented-interface:
    #/home/tim/dev/idexperts/api/src/github.com/radartools/api/cmd/api/tokens.go <unknown> 27        r.Get(api.TokensPostRoute).HandlerFunc(m.tokensPost)
    @@cscope_line_regexp = /^(\S+)\s(\S+)\s(\d+)\s+(.+)$/

    def initialize(cscope_db)
      @cscope_db = cscope_db
      init_cscope_connection
    end

    def query(pattern, query_type = CscopeQuery::Egrep)
      pattern = generate_cscope_pattern(pattern)

      result = []
      #TODO: detect when cscope has a file that no longer exists in it's database
      #in that case it will print the following to stderr:
      #  Cannot open file /foo.go
      IO.popen("cscope -dC -L -f'#{@cscope_db}' -#{query_type}'#{pattern}' 2> /dev/null", 'w+') do |sp|
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
      pattern = base.downcase #in order to do case insensitive matching cscope requires lower case
      return "^(.* )?#{pattern}" if pattern.length <= 2
      return "^(.* )?#{pattern}"
      #return '^(.* )?p[a-zA-Z0-9]*a'
    end
  end
end
