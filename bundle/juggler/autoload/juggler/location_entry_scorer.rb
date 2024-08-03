module Juggler
  class LocationEntryScorer
    # Used to calculate the `score` of a LocationEntry - the higher the
    # `score`, the better a match we consider the LocationEntry

    # Weight how match properties are treated - higher means more important
    @weights = {
      exact_match: 1000,
      case_insensitive_match: 100,
      starts_with: 12,
      case_insensitive_starts_with: 11,
      exact_first_letter: 10,
      case_insensitive_first_letter: 4,
      has_any_match: 1, # Did the entry match at all? Helps filter out results returned by plugins that actually don't match at all
      important_letter_weight: 1,
      extension_matches_filetype: 2,
      same_file: 3,
      proximity_to_current_line: 8,
      invalid_omni: -1000000,
    }
    def self.weights; @weights; end
    def weights; self.class.weights; end

    def initialize(cursor_info:, search_text:, searching_filepaths: false)
      @cursor_info = cursor_info
      @search_text = search_text
      @searching_filepaths = searching_filepaths
    end

    def score(entry)
      score_data = {score: 0, match_data: []}

      if @searching_filepaths
        score_for_search_text(score_data, File.basename(entry.file), multiplier: 2)
        if score_data[:score].zero?
          score_for_search_text(score_data, entry.file)
        end
      else
        score_for_search_text(score_data, entry.description)
      end

      score_data
    end

    def score_for_search_text(score_data, match_text_to_score, multiplier: 1)
      return if @search_text.nil? || @search_text.empty?

      md = match_text_to_score.match(search_regex)
      return if md.nil?

      # We at least matched what was searched for, add that up front
      # add_match(score_data, type: :has_any_match, multiplier: multiplier, matched_text: md[0])
      add_match(score_data, type: :has_any_match, multiplier: multiplier, matched_text: match_for_display(match_text_to_score, md.begin(0), md.end(0)))

      # starts_with
      if match_text_to_score.start_with?(@search_text)
        add_match(score_data, type: :starts_with, multiplier: multiplier, matched_text: match_for_display(match_text_to_score, 0, @search_text.size))
      elsif match_text_to_score.downcase.start_with?(@search_text.downcase)
        add_match(score_data, type: :case_insensitive_starts_with, multiplier: multiplier, matched_text: match_for_display(match_text_to_score, 0, @search_text.size))
      end

      # exact_first_letter
      if @search_text[0] == match_text_to_score[0]
        add_match(score_data, type: :exact_first_letter, multiplier: multiplier, matched_text: match_for_display(match_text_to_score, 0, 1))
      elsif @search_text[0].casecmp(match_text_to_score[0]) == 0
        add_match(score_data, type: :case_insensitive_first_letter, multiplier: multiplier, matched_text: match_for_display(match_text_to_score, 0, 1))
      end

      # Figure out the important letters and if they match our search text
      chars = match_text_to_score.codepoints
      (1..(md.size - 1)).each do |i| # Iterate over all the non-global (zero index) matches
        # Can do `md.begin(i)` to get the index of match group `i`
        start = md.begin(i)
        next if start.zero? # We already dealt with a match at the beginning up above

        # NOTE: this only works on codebases that are primarily ASCII - I've never worked on one
        # that isn't, so not going to bother with that until I encounter one.

        # First check if the matched character is an uppercase alpha character (A == 65, Z == 90)
        # If it is, then check if the previous character is not an uppercase alpha character
        char = chars[start]
        if char >= 65 && char <= 90
          prev_char = chars[start - 1]
          add_match(score_data, type: :important_letter_weight, multiplier: multiplier, matched_text: match_for_display(match_text_to_score, start, start + 1)) if prev_char < 65 || prev_char > 90

        # Now check if the matched character is a lowercase alpha character (a == 97, z == 122)
        # If it is, then check if the previous character is a non-alph character
        elsif char >= 97 && char <= 122
          prev_char = chars[start - 1]
          add_match(score_data, type: :important_letter_weight, multiplier: multiplier, matched_text: match_for_display(match_text_to_score, start, start + 1)) if prev_char < 65 || (prev_char > 90 && prev_char < 97) || prev_char > 122
        end
      end
    end

    def add_match(score_data, type:, weight: nil, multiplier: 1, matched_text: nil)
      weight = weights[type] if weight.nil?
      match_data = {type: type, weight: weight}
      match_data[:matched_text] = matched_text unless matched_text.nil?
      if multiplier != 1
        match_data[:weight] = weight = (weight * multiplier)
        match_data[:multiplier] = multiplier
      end
      score_data[:score] += weight
      score_data[:match_data] << match_data
    end

    def search_regex
      @search_regex ||= Regexp.new("(#{@search_text.scan(/./).join(').*(')})", Regexp::IGNORECASE)
    end

    # Draws brackets `[]` around what was matched
    def match_for_display(text, start, finish)
      "#{text[0, start]}[#{text[start..(finish - 1)]}]#{text[finish..-1]}"
    end
  end
end
