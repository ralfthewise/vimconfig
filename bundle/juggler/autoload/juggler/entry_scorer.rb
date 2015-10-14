module Juggler
  class EntryScorer
    def initialize(search_text, current_file, current_line)
      @search_text = search_text
      @current_file = current_file
      @current_line = current_line

      @proximity_to_current_line_threshold = 5 #must be within this number of lines to get the proximity weight

      #weight how match properties are treated - higher means more important
      @exact_match = 1000
      @case_insensitive_match = 100
      @same_file = 2
      @exact_first_letter = 10
      @case_insensitive_first_letter = 4
      @important_letter_weight = 1
      @extension_matches_filetype = 2
      @proximity_to_current_line = 5
      @entry_source_weights = {
        keyword: 0,
        omni: 3, #omni can't include file/line info, so this helps balance that lack
        ctags: 0,
        cscope: 0
      }
    end

    def score(entry)
      return 0 if @search_text.nil? || @search_text.empty? || entry.tag.nil? || entry.tag.empty?

      score = 0

      #check for full match or first letter match
      case
      when entry.tag == @search_text then score += @exact_match
      when @search_text.casecmp(entry.tag) == 0 then score += @case_insensitive_match
      when @search_text[0] == entry.tag[0] then score += @exact_first_letter
      when @search_text[0].casecmp(entry.tag[0]) == 0 then score += @case_insensitive_first_letter
      end

      #check for same file
      if entry.file == @current_file
        score += @same_file
        #check for proximity to current line
        if !entry.line.nil? && (entry.line - @current_line).abs <= @proximity_to_current_line_threshold
          score += @proximity_to_current_line
        end
      end

      #adjust for entry source
      score += @entry_source_weights[entry.source].to_i

      return score
    end
  end
end
