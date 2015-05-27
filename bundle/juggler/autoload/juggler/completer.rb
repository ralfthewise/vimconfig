require 'singleton'
require_relative 'omni_completer'
require_relative 'ctags_completer'
require_relative 'keyword_completer'
require_relative 'entry_scorer'
require_relative 'completion_entries'

module Juggler
  class Completer
    include Singleton

    def initialize
      @use_omni = VIM::evaluate('g:juggler_useOmniCompleter') == 1
      @use_tags = VIM::evaluate('g:juggler_useTagsCompleter') == 1
      @use_keyword = VIM::evaluate('g:juggler_useKeywordCompleter') == 1

      @omni_completer = OmniCompleter.new if @use_omni
      @ctags_completer = CtagsCompleter.new if @use_tags
      @keyword_completer = KeywordCompleter.new if @use_keyword
    end

    def generate_completions
      cursor_info = VIM::evaluate('s:cursorinfo')
      scorer = EntryScorer.new(cursor_info['token'])
      entries = CompletionEntries.new

      #omni completions
      if @use_omni
        @omni_completer.generate_completions(cursor_info['token']) do |entry|
          entry.score = scorer.score(entry)
          entries.push(entry)
        end
      end

      #ctags completions
      if @use_tags
        @ctags_completer.generate_completions(cursor_info['token']) do |entry|
          entry.score = scorer.score(entry)
          entries.push(entry)
        end
      end

      #keywords completions
      if @use_keyword
        @keyword_completer.generate_completions(cursor_info['token']) do |entry|
          entry.score = scorer.score(entry)
          entries.push(entry)
        end
      end

      entries.process do |vim_arr|
        VIM::command("call extend(s:juggler_completions, [#{vim_arr}])")
      end
    end
  end
end
