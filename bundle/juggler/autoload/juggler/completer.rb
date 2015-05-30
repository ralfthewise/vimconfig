require 'singleton'
require_relative 'omni_completer'
require_relative 'ctags_completer'
require_relative 'cscope_completer'
require_relative 'keyword_completer'
require_relative 'entry_scorer'
require_relative 'completion_entries'

module Juggler
  class Completer
    include Singleton

    def initialize
      @omni_completer = OmniCompleter.new
      @ctags_completer = CtagsCompleter.new
      @cscope_completer = CscopeCompleter.new
      @keyword_completer = KeywordCompleter.new
    end

    def generate_completions
      cursor_info = VIM::evaluate('s:cursorinfo')
      scorer = EntryScorer.new(cursor_info['token'])
      entries = CompletionEntries.new

      #omni completions
      @omni_completer.generate_completions(cursor_info['token']) do |entry|
        entry.score = scorer.score(entry)
        entries.push(entry)
      end

      #ctags completions
      @ctags_completer.generate_completions(cursor_info['token']) do |entry|
        entry.score = scorer.score(entry)
        entries.push(entry)
      end

      #cscope completions
      @cscope_completer.generate_completions(cursor_info['token']) do |entry|
        entry.score = scorer.score(entry)
        entries.push(entry)
      end

      #keywords completions
      @keyword_completer.generate_completions(cursor_info['token']) do |entry|
        entry.score = scorer.score(entry)
        entries.push(entry)
      end

      entries.process do |vim_arr|
        VIM::command("call extend(s:juggler_completions, [#{vim_arr}])")
      end
    end
  end
end
