module Juggler
  class CompletionEntry
    attr_accessor :tag, :index, :pri, :kind, :file, :info, :signature, :line, :excmd, :score

    def initialize(index: nil, pri: nil, kind: nil, tag: nil, file: nil)
      self.index = index
      self.pri = pri
      self.kind = kind
      self.tag = tag
      self.file = file
    end

    def to_vim_dict
      return "{'word':'%s','menu':'%s','kind':'%s','info':'%s - %s'}" % [tag, signature, kind, file, info].map{|x| Juggler.escape_vim_singlequote_string(x)}
    end
  end
end
