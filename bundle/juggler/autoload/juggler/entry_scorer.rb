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
      @extension_matches_filetype = 2
      @proximity_to_cursor = 5
      @entry_source_weights = {
        omni: 1,
        ctags: 1
      }
    end

    def score(entry)
      score = 0
      if entry.tag == @search_text
        score += @exact_match
      elsif @search_text.casecmp(entry.tag) == 0
        score += @case_insensitive_match
      end

      return score
    end
  end
end