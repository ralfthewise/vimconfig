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
        project_dir = determine_project_dir
        if project_dir.nil?
          @use_tags = @manage_tags = @use_cscope = @manage_cscope = false
          return
        end

        digest = Digest::SHA1.hexdigest(project_dir)
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
      Juggler.logger.debug("Generating completions for: #{cursor_info['token']}")
      scorer = EntryScorer.new(cursor_info['token'])
      entries = CompletionEntries.new

      #omni completions
      if @use_omni
        start = Time.now
        count = 0
        @omni_completer.generate_completions(cursor_info['token']) do |entry|
          entry.score = scorer.score(entry)
          entries.add(entry)
          count += 1
        end
        Juggler.logger.debug { "omni completions took #{Time.now - start} seconds and found #{count} entries" }
      end

      #ctags completions
      if @use_tags
        start = Time.now
        count = 0
        @ctags_completer.generate_completions(cursor_info['token']) do |entry|
          entry.score = scorer.score(entry)
          entries.add(entry)
          count += 1
        end
        Juggler.logger.debug { "ctags completions took #{Time.now - start} seconds and found #{count} entries" }
      end

      #cscope completions
      if @use_cscope
        start = Time.now
        count = 0
        @cscope_completer.generate_completions(cursor_info['token']) do |entry|
          entry.score = scorer.score(entry)
          entries.add(entry)
          count += 1
        end
        Juggler.logger.debug { "cscope completions took #{Time.now - start} seconds and found #{count} entries" }
      end

      #keywords completions
      if @use_keyword
        start = Time.now
        count = 0
        @keyword_completer.generate_completions(cursor_info['token']) do |entry|
          entry.score = scorer.score(entry)
          entries.add(entry)
          count += 1
        end
        Juggler.logger.debug { "keywords completions took #{Time.now - start} seconds and found #{count} entries" }
      end

      Juggler.logger.info { "#{entries.count} total entries found" }
      entries.process do |vim_arr|
        VIM::command("call extend(s:juggler_completions, [#{vim_arr}])")
      end
    end

    protected
    def determine_project_dir
      cwd = VIM::evaluate('getcwd()')
      buf = File.absolute_path(VIM::evaluate('bufname("%")'))
      buf_wd = File.expand_path('..', buf)
      result = walk_tree_looking_for_project(cwd)
      result = walk_tree_looking_for_project(buf_wd) if result.nil?
      Dir.chdir(cwd)
      return result
    end

    def walk_tree_looking_for_project(cwd)
      #walk up the tree until we find a VCS entry
      while valid_project_dir?(cwd)
        Dir.chdir(cwd)
        if Dir.glob(['.git']).length > 0
          return cwd
        end
        cwd = File.expand_path('..')
      end
      return nil
    end

    def valid_project_dir?(d)
      return false if d == Dir.home
      return false if d == '/'
      return true
    end
  end
end
