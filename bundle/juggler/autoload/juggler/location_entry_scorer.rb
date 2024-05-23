module Juggler
  class LocationEntryScorer
    # Used to calculate the `score` of a LocationEntry - the higher the
    # `score`, the better a match we consider the LocationEntry
    def initialize(cursor_location:, search_text:, searching_filepaths: false)
      @cursor_location = cursor_location
      @search_text = search_text
      @searching_filepaths = searching_filepaths
    end

    def score(entry)
      0
    end
  end
end
