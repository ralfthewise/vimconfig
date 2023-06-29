module Juggler
  class CompletionEntry
    @@max_menu_info_length = 64

    #to match lines like: /^    foo = (a) ->$/
    @@excmd_regexp = /^\/\^\s*(.*\S)\s*\$\/$/

    attr_accessor :source, :tag, :index, :pri, :kind, :file, :info, :signature, :line, :excmd, :score_data

    def initialize(source:, tag:, line: nil, index: nil, pri: nil, kind: nil, file: nil, signature: nil, info: nil)
      self.source = source
      self.tag = tag
      self.line = line
      self.index = index
      self.pri = pri
      self.kind = kind
      self.file = file
      self.signature = signature
      self.info = info
    end

    def duplicate
      dup = self.class.new(source: source, tag: tag, line: line, index: index, pri: pri, kind: kind, file: file, signature: signature, info: info)
      dup.score_data = score_data.clone unless score_data.nil?
      dup.excmd = excmd
      return dup
    end

    # See :help complete-items
    #   word - the text that will be inserted, mandatory
    #   menu - extra text for the popup menu, displayed after "word"
    #   info - more information about the item
    #   kind - single letter indicating type of completion
    #     v - variable
    #     f - function or method
    #     m - member of a struct or class
    #     t - typedef
    #     d - #define or macro
    #   HOWEVER, it turns out you can set `kind` to any string so we just do things like 'method', 'variable', etc
    def to_vim_dict
      #extra spaces here help visually separate term from description in popup menu
      return "{'word':'%s','menu':'  %s','kind':'  %s','info':'%s'}" % [tag, generate_menu_info, kind, generate_preview_info].map{|x| Juggler.escape_vim_singlequote_string(x)}
    end

    def to_s
      return {tag:tag,source:source,score_data:score_data,line:line,file:file,kind:kind,info:info}.to_s
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
