module Juggler
  class EntryScorer
    def initialize(search_text, current_file, current_line)
      @search_text = search_text
      @search_regex = Regexp.new('\w*' + search_text.scan(/./).join('\w*') + '\w*', Regexp::IGNORECASE)
      @current_file = current_file
      @current_line = current_line

      @proximity_to_current_line_threshold = 20 #must be within this number of lines to get the proximity weight

      #weight how match properties are treated - higher means more important
      @weights = {
        exact_match: 1000,
        case_insensitive_match: 100,
        starts_with: 12,
        case_insensitive_starts_with: 11,
        exact_first_letter: 10,
        case_insensitive_first_letter: 4,
        important_letter_weight: 1,
        extension_matches_filetype: 2,
        same_file: 3,
        proximity_to_current_line: 8,
        invalid_omni: -1000000
      }
      @entry_source_weights = {
        lsp: 20, #language server protocol is the best when it works
        keyword: 1, #keywords is slightly better than ctags/cscope since it operates on the (potentially not yet saved) buffer
        omni: 2, #omni can't include file/line info, so this helps balance that lack
        omnitrigger: 2,
        ctags: 0,
        cscope: 0
      }
    end

    def score(entry)
      score_data = {score: 0.to_f, match_data: {}}

      return score_data if @search_text.nil? || @search_text.empty? || entry.tag.nil? || entry.tag.empty?

      #check for full match or first letter match
      case
      when entry.tag == @search_text then add_match(score_data, :exact_match)
      when @search_text.casecmp(entry.tag) == 0 then add_match(score_data, :case_insensitive_match)
      when entry.tag.start_with?(@search_text) then add_match(score_data, :starts_with)
      when entry.tag.downcase.start_with?(@search_text.downcase) then add_match(score_data, :case_insensitive_starts_with)
      when @search_text[0] == entry.tag[0] then add_match(score_data, :exact_first_letter)
      when @search_text[0].casecmp(entry.tag[0]) == 0 then add_match(score_data, :case_insensitive_first_letter)
      else
        #figure our the important letters and if they match our search text
      end

      #fucking omni completion sometimes matches shit that isn't even what was typed in!
      add_match(score_data, :invalid_omni) if entry.source == :omni && !(@search_regex =~ entry.tag)

      #check for same file
      if entry.file == @current_file
        add_match(score_data, :same_file)
        #check for proximity to current line
        if !entry.line.nil? && (entry.line - @current_line).abs <= @proximity_to_current_line_threshold
          #TODO - improve the algorithm to rank proximity to current line
          weight = @weights[:proximity_to_current_line] * ((@proximity_to_current_line_threshold - (entry.line - @current_line).abs) / @proximity_to_current_line_threshold.to_f)
          add_match(score_data, :proximity_to_current_line, weight)
        end
      end

      #adjust for entry source
      score_data[:score] += @entry_source_weights[entry.source]
      score_data[:match_data][entry.source] = @entry_source_weights[entry.source]

      return score_data
    end

    protected
    def add_match(score_data, match_type, weight = nil)
      weight = @weights[match_type] if weight.nil?
      score_data[:score] += weight
      score_data[:match_data][match_type] = weight
    end
  end
end
