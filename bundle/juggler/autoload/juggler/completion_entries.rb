module Juggler
  class CompletionEntries
    @@max_entries_to_return = 100

    attr_accessor :entries

    def initialize
      self.entries = []
    end

    def count
      return self.entries.length
    end

    def push(entry)
      self.entries.push(entry)
    end

    def process
      start = Time.now
      self.entries.sort! do |a,b|
        result = b.score - a.score
        if !a.tag.nil? && !b.tag.nil?
          result = a.tag.length - b.tag.length if result == 0
        end
        result
      end
      Juggler.logger.debug { "sorting completion entries took #{Time.now - start} seconds" }

      vim_entries = self.entries[0..(@@max_entries_to_return - 1)].map {|e| e.to_vim_dict}

      #TODO: yield in batches
      yield(vim_entries.join(','))
    end
  end
end
