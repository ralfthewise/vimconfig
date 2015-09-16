module Juggler
  class CompletionEntries
    @@max_entries_to_return = 20

    attr_accessor :entries

    def initialize
      self.entries = {}
    end

    def count
      return self.entries.length
    end

    def add(entry)
      self.entries[entry.tag] = entry unless entry.tag.nil? || self.entries.include?(entry.tag)
    end

    def process
      start = Time.now
      vim_entries = self.entries.values
      vim_entries.sort! do |a,b|
        result = b.score - a.score
        if !a.tag.nil? && !b.tag.nil?
          result = a.tag.length - b.tag.length if result == 0
        end
        result
      end
      Juggler.logger.debug { "sorting completion entries took #{Time.now - start} seconds" }

      vim_entries = vim_entries[0..(@@max_entries_to_return - 1)].map {|e| e.to_vim_dict}

      #TODO: yield in batches
      yield(vim_entries.join(','))
    end
  end
end
