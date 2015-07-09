require 'fileutils'
require 'singleton'
require 'digest/sha1'
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
      @use_omni = VIM::evaluate('g:juggler_useOmniCompleter') == 1
      @use_tags = VIM::evaluate('g:juggler_useTagsCompleter') == 1
      @use_cscope = VIM::evaluate('g:juggler_useCscopeCompleter') == 1
      @use_keyword = VIM::evaluate('g:juggler_useKeywordCompleter') == 1

      @omni_completer = OmniCompleter.new if @use_omni
      @ctags_completer = CtagsCompleter.new if @use_tags
      @cscope_completer = CscopeCompleter.new if @use_cscope
      @keyword_completer = KeywordCompleter.new if @use_keyword

      @indexes_path = nil
    end

    def init_indexes
      if @indexes_path.nil?
        cwd = VIM::evaluate('getcwd()')
        digest = Digest::SHA1.hexdigest(cwd)
        @indexes_path = File.join(Dir.home, '.vim_indexes', digest)
        FileUtils.mkdir_p(@indexes_path)
        VIM::command("let s:indexespath = '#{Juggler.escape_vim_singlequote_string(@indexes_path)}'")
      end
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

      #cscope completions
      if @use_cscope
        @cscope_completer.generate_completions(cursor_info['token']) do |entry|
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
