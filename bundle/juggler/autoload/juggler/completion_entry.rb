module Juggler
  class CompletionEntry
    @@max_menu_info_length = 64

    #to match lines like: /^    foo = (a) ->$/
    @@excmd_regexp = /^\/\^\s*(.*\S)\s*\$\/$/

    attr_accessor :source, :tag, :index, :pri, :kind, :file, :info, :signature, :line, :excmd, :score

    def initialize(source: nil, tag: nil, line: nil, index: nil, pri: nil, kind: nil, file: nil, signature: nil, info: nil)
      raise Exception.new(':source is a required') if source.nil?

      self.source = source
      self.tag = tag
      self.index = index
      self.pri = pri
      self.kind = kind
      self.file = file
      self.signature = signature
      self.info = info
    end

    def to_vim_dict
      return "{'word':'%s','menu':'  %s','kind':'  %s','info':'%s'}" % [tag, generate_menu_info, kind, generate_preview_info].map{|x| Juggler.escape_vim_singlequote_string(x)}
    end

    def to_s
      return to_vim_dict
    end

    protected
    def generate_menu_info
      result = signature

      if !result && excmd
        if match = @@excmd_regexp.match(excmd)
          result = match[1].rstrip
        else
          result = excmd
        end
      end

      result = '' unless result
      return result[0..@@max_menu_info_length]
    end

    def generate_preview_info
      "#{file} - #{info}"
    end
  end
end
