require 'forwardable'

module Juggler
  class LocationEntryCollection
    # Collects, de-duplicates, and sorts LocationEntrys

    # How many entries to show in the logs
    NUM_PRETTY_LOG_ENTRIES = 5

    # Many methods we just forward on the our `@entries` property
    extend ::Forwardable
    def_delegators :@entries, :length, :size, :[], :<<, :to_a, :map

    def initialize(cursor_info, search_text)
      @cursor_info = cursor_info
      @search_text = search_text
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

    def sort!(searching_filepaths: false)
      scorer = LocationEntryScorer.new(cursor_info: @cursor_info, search_text: @search_text, searching_filepaths: searching_filepaths)
      @entries.map! {|e| ScoredLocationEntry.new(e, scorer)}
      @entries.sort! do |a, b|
        next b.score[:score] <=> a.score[:score] if a.score[:score] != b.score[:score]
        next a.file <=> b.file if a.file != b.file

        # a.line.to_s.rjust(5, '0') <=> b.line.to_s.rjust(5, '0')
        a.line.to_i <=> b.line.to_i
      end
      # @entries.sort_by!{|e| "#{e.file}:#{e.line.to_s.rjust(5, '0')}"}
      self
    end

    def pretty_log
      "Search Text: #{@search_text}\nCursor Info:\n#{@cursor_info.pretty_log(2)}\nEntries:\n" +
        @entries[0..(NUM_PRETTY_LOG_ENTRIES - 1)].map {|e| e.pretty_log(2)}.join("\n  --------\n") +
        (@entries.size - NUM_PRETTY_LOG_ENTRIES > 0 ? "\n  ... and #{@entries.size - NUM_PRETTY_LOG_ENTRIES} more\n" : "\n")
    end
  end
end
