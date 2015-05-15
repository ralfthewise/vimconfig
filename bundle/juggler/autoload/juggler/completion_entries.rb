module Juggler
  class CompletionEntries
    attr_accessor :entries

    def initialize
      self.entries = []
    end

    def push(entry)
      self.entries.push(entry)
    end

    def process
      self.entries.sort! do |a,b|
        result = b.score - a.score
        if !a.tag.nil? && !b.tag.nil?
          result = a.tag.length - b.tag.length if result == 0
        end
        result
      end

      vim_entries = self.entries.map {|e| e.to_vim_dict}
      #TODO: yield in batches
      yield(vim_entries.join(','))
    end
  end
end
