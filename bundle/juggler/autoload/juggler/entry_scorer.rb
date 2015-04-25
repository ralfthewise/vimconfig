module Juggler
  class EntryScorer
    def initialize(search_text)
      @search_text = search_text

      #weight how match properties are treated - higher means more important
      @exact_match = 1000
      @case_insensitive_match = 100
      @same_file = 2
      @exact_first_letter = 10
      @case_insensitive_first_letter = 4
      @important_letter_weight = 1
    end

    def score(entry)
      return @exact_match if entry.tag == @search_text
      return @case_insensitive_match if @search_text.casecmp(entry.tag) == 0
      return 1
    end
  end
end
