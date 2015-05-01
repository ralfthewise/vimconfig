require 'singleton'
require_relative 'omni_completer'
require_relative 'ctags_completer'
require_relative 'entry_scorer'
require_relative 'completion_entries'

module Juggler
  class Completer
    include Singleton

    def initialize
      @omni_completer = OmniCompleter.new
      @ctags_completer = CtagsCompleter.new
    end

    def generate_completions
      #TODO: calculate base instead of using what was passed in by vim
      base = VIM::evaluate('a:base')
      scorer = EntryScorer.new(base)
      entries = CompletionEntries.new

      #omni completions
      @omni_completer.generate_completions do |entry|
        entry.score = scorer.score(entry)
        entries.push(entry)
      end

      #ctags completions
      @ctags_completer.generate_completions(base) do |entry|
        entry.score = scorer.score(entry)
        entries.push(entry)
      end

      entries.process do |vim_arr|
        VIM::command("call extend(s:juggler_completions, [#{vim_arr}])")
      end
    end
  end
end
