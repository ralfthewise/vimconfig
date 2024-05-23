module Juggler
  class LocationEntryCollection
    # Collects, de-duplicates, and sorts LocationEntrys

    def initialize
      @entries_map = {}
      @entries = []
    end

    def add(new_entries)
      new_entries.to_a.each do |e|
        if (found = @entries_map[e.key])
          # We already have an entry for this particular location, let's just merge them
          found.merge(e)
        else
          @entries_map[e.key] = e
          @entries << e
        end
      end
    end

    def sort!
      @entries.sort_by!{|e| "#{e.file}:#{e.line.to_s.rjust(5, '0')}"}
      self
    end

    def map(&block)
      @entries.map(&block)
    end
  end
end
