require_relative 'completion_entry'

module Juggler
  class CtagsCompleter
    #columns are:
    #  #  pri kind tag               file

    #example match:
    #   2 F   fieldradarService ./test-ui/spec/1.2/incidents/incidents/controllers/exposed-controller.spec.coffee
    #                line:40 language:coffee
    #                radarService: $radarService

    #or:
    #  29 F   v    radarUrl          ./test-ui/integration/header_test.go
    #                access:private line:16 type:string
    #                16
    @@ctag_line1_regexp = /^>?\s+(\d+)\s+([FSC]*)\s+(\w{,5})\s*(\S+)\s+(\S+)$/
    @@ctag_info_line_regexp = /([^:\s]+:[^:]+)(\s|$)/
    @@digit_regexp = /^\d+$/

    def generate_completions(base)
      return if base.nil? || base.empty?

      ctag_output = VIM::evaluate("s:GetTags('/#{Juggler.escape_vim_singlequote_string(base)}')")
      entry = nil
      ctag_output.split("\n").each do |line|
        if entry.nil?
          if match = @@ctag_line1_regexp.match(line)
            entry = CompletionEntry.new(source: :ctags, index: match[1], pri: match[2], kind: match[3], tag: match[4], file: match[5])
          end
        else
          info_match = line.scan(@@ctag_info_line_regexp).map {|m| m.first}
          if !info_match.empty?
            entry.info = line.strip
            info_match.each do |info|
              info_pair = info.split(':')
              case info_pair[0]
              when 'signature' then entry.signature = info_pair[1]
              when 'line' then entry.line = info_pair[1].to_i
              end
            end
          else
            entry.excmd = line.strip
            entry.line = entry.excmd.to_i if @@digit_regexp.match(entry.excmd)
            yield(entry)
            entry = nil
          end
        end
      end
      yield(entry) unless entry.nil?
    end

    protected
    def generate_ctag_pattern(base)
      return base.scan(/./).join('.*')
    end
  end
end
