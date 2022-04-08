require_relative 'omni_completer'

module Juggler::Plugins
  class CachingOmniCompleter < OmniCompleter
    def initialize(options, use_omni_trigger_cache = true)
      @use_omni_trigger_cache = use_omni_trigger_cache
      @last_linenum = -1
      @last_matchstart = -1
      @last_token = ''

      @cached_entries = []
    end

    def generate_completions(token, cursor_info)
      #first let's determine if we should use the cache
      use_cache_for_this_completion = false
      if @use_omni_trigger_cache
        Juggler.logger.info { "Checking if we should use cache: last_linenum - #{@last_linenum}, last_matchstart - #{@last_matchstart}, last_token - #{@last_token}" }
        if @last_linenum == cursor_info['linenum'] && @last_matchstart == cursor_info['matchstart']
          #linenum and the index of the beginning of the token match up, let's see if the token and our last_token share a prefix
          min_token_length = [@last_token.length, token.length].min
          if @last_token[0,min_token_length] == token[0,min_token_length]
            use_cache_for_this_completion = true
          end
        end
      end

      token_regex = Regexp.new(generate_match_pattern(token), Regexp::IGNORECASE)

      #now actually generate our list of entries
      if use_cache_for_this_completion
        Juggler.logger.info { 'Using cached omni completions' }
        @cached_entries.each do |entry|
          yield(entry) if token_regex.match(entry.tag)
        end
      else
        @last_linenum = cursor_info['linenum']
        @last_matchstart = cursor_info['matchstart']
        @last_token = token
        @cached_entries = [] if @use_omni_trigger_cache
        super do |entry|
          if token_regex.match(entry.tag)
            entry = entry.duplicate
            entry.source = :omnitrigger
            yield(entry)
            @cached_entries.push(entry) if @use_omni_trigger_cache
          end
        end
      end
    end

    protected
    def generate_match_pattern(base)
      return '\w*' + base.scan(/./).join('\w*') + '\w*'
    end
  end
end
