module Juggler
  class CompletionEntry
    attr_accessor :source, :tag, :index, :pri, :kind, :file, :info, :signature, :line, :excmd, :score

    def initialize(source:, tag: nil, line: nil, index: nil, pri: nil, kind: nil, file: nil, signature: nil, info: nil)
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
      return "{'word':'%s','menu':'%s','kind':'%s','info':'%s - %s'}" % [tag, signature, kind, file, info].map{|x| Juggler.escape_vim_singlequote_string(x)}
    end
  end
end
