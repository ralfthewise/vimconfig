require 'fileutils'
require 'singleton'
require 'digest/sha1'
require_relative 'cscope_service'
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
      @manage_tags = VIM::evaluate('g:juggler_manageTags') == 1
      @use_cscope = VIM::evaluate('g:juggler_useCscopeCompleter') == 1
      @manage_cscope = VIM::evaluate('g:juggler_manageCscope') == 1
      @use_keyword = VIM::evaluate('g:juggler_useKeywordCompleter') == 1

      init_indexes
      init_completers
    end

    def init_indexes
      if ((@use_tags && @manage_tags) || (@use_cscope && @manage_cscope))
        #TODO: don't use getcwd() but instead be smart about where the project root is
        cwd = VIM::evaluate('getcwd()')
        digest = Digest::SHA1.hexdigest(cwd)
        @indexes_path = File.join(Dir.home, '.vim_indexes', digest)
        FileUtils.mkdir_p(@indexes_path)
        VIM::command("let s:indexespath = '#{Juggler.escape_vim_singlequote_string(@indexes_path)}'")
        @cscope_service = CscopeService.new(File.join(@indexes_path, 'cscope.out')) if (@use_cscope && @manage_cscope)
      end
    end

    def init_completers
      @omni_completer = OmniCompleter.new if @use_omni
      @ctags_completer = CtagsCompleter.new if @use_tags
      @cscope_completer = CscopeCompleter.new(@cscope_service) if @use_cscope
      @keyword_completer = KeywordCompleter.new if @use_keyword
    end

    def generate_completions
      cursor_info = VIM::evaluate('s:cursorinfo')
      scorer = EntryScorer.new(cursor_info['token'])
      entries = CompletionEntries.new

      #omni completions
      if @use_omni
        start = Time.now
        @omni_completer.generate_completions(cursor_info['token']) do |entry|
          entry.score = scorer.score(entry)
          entries.push(entry)
        end
        Juggler.logger.debug { "omni completions took #{Time.now - start} seconds" }
      end

      #ctags completions
      if @use_tags
        start = Time.now
        @ctags_completer.generate_completions(cursor_info['token']) do |entry|
          entry.score = scorer.score(entry)
          entries.push(entry)
        end
        Juggler.logger.debug { "ctags completions took #{Time.now - start} seconds" }
      end

      #cscope completions
      if @use_cscope
        start = Time.now
        @cscope_completer.generate_completions(cursor_info['token']) do |entry|
          entry.score = scorer.score(entry)
          entries.push(entry)
        end
        Juggler.logger.debug { "cscope completions took #{Time.now - start} seconds" }
      end

      #keywords completions
      if @use_keyword
        start = Time.now
        @keyword_completer.generate_completions(cursor_info['token']) do |entry|
          entry.score = scorer.score(entry)
          entries.push(entry)
        end
        Juggler.logger.debug { "keywords completions took #{Time.now - start} seconds" }
      end

      Juggler.logger.info { "#{entries.count} entries found" }
      entries.process do |vim_arr|
        VIM::command("call extend(s:juggler_completions, [#{vim_arr}])")
      end
    end
  end
end
