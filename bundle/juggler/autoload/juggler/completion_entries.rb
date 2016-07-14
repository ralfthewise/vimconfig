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
      return if entry.tag.nil?
      existing = self.entries[entry.tag]
      if existing.nil? || existing.score_data[:score] < entry.score_data[:score]
        self.entries[entry.tag] = entry
        entry.signature = existing.signature if (!existing.nil? && (entry.signature.nil? || entry.signature.empty?))
      end
      #if existing.nil?
      #  self.entries[entry.tag] = entry
      #else
      #  if existing.score_data[:score] < entry.score_data[:score]
      #    self.entries[entry.tag] = entry
      #  else
      #    Juggler.logger.debug { "Skipping #{entry}" }
      #  end
      #end
    end

    def process
      start = Time.now
      vim_entries = self.entries.values
      vim_entries.sort! do |a,b|
        result = b.score_data[:score] - a.score_data[:score]
        if !a.tag.nil? && !b.tag.nil?
          result = a.tag.length - b.tag.length if result == 0
        end
        result = -1 if result < 0
        result = 1 if result > 0
        result
      end
      Juggler.logger.info { "Sorting completion entries took #{Time.now - start} seconds" }

      vim_entries = vim_entries[0..(@@max_entries_to_return - 1)]
      Juggler.logger.debug do
        log = "Entries:"
        vim_entries.each {|e| log += "\n  #{e}"}
        log
      end
      vim_entries = vim_entries.map {|e| e.to_vim_dict}

      yield('[' + vim_entries.join(',') + ']')
    end
  end
end
