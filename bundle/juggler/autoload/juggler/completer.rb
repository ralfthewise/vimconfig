require 'fileutils'
require 'singleton'
require 'shellwords'
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
      @log_level = ENV['JUGGLER_LOG_LEVEL'] || VIM::evaluate('g:juggler_logLevel')
      #TODO: load these on each completion
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

    def find
      Juggler.with_status('Searching...') do
        srchstr = VIM::evaluate('srchstr').to_s
        next if srchstr == ''
        grep_cmd = 'ag --nogroup --nocolor --vimgrep --hidden'
        strip_tabs_cmd = "sed 's/\\t/  /g'" #sometimes cexpr and cgetexpr have issues with tabs
        if srchstr.start_with?('/')
          srchstr = srchstr[1..-1] #strip off beginning '/'
          grep_cmd += ' --case-sensitive'
        else
          srchstr = srchstr[1..-1] if srchstr.start_with?('\/') #strip off beginning '\'
          grep_cmd += ' --smart-case --literal'
        end
        grep_cmd = "#{find_files_cmd} -exec #{grep_cmd} #{Shellwords.escape(srchstr)} {} +"

        start = Time.now
        result = `#{grep_cmd} | #{strip_tabs_cmd}`
        result = result.gsub("\r\n", "\n").gsub("\r", "\n")
        result = Juggler.clean_utf8(result).split("\n")
        Juggler.logger.debug do
          "Searching for the pattern: #{srchstr}\n" +
          "  Using grep command: #{grep_cmd}\n" +
          "  Text search took #{Time.now - start} seconds\n" +
          "  Num results: #{result.length}\n" +
          "  Result:\n#{result.join("\n")}"
        end
        result = result.map {|entry| "\"#{Juggler.escape_vim_doublequote_string(entry.strip[0..191])}\""}.join(',')
        VIM::command("cgetexpr [#{result}]")

        #VIM::command("cgetexpr split(\"#{Juggler.escape_vim_doublequote_string(result)}\", \"\\n\")")
        #VIM::command("cgetexpr system('#{Juggler.escape_vim_singlequote_string(grep_cmd)} \\| #{Juggler.escape_vim_singlequote_string(strip_tabs_cmd)}')")

        VIM::command('copen')
        Juggler.refresh
      end
    end

    def update_indexes(only_current_file: 0)
      if ((@use_tags && @manage_tags) || (@use_cscope && @manage_cscope))
        only_current_file = 0 if !File.exists?(File.join(@indexes_path, 'tags.files')) || !File.exists?(File.join(@indexes_path, 'cscope.files'))
        cd_cmd = "cd #{Shellwords.escape(@indexes_path)}"
        ctags_cmd = "echo #{Shellwords.escape($curbuf.name)} | ctags --append --fields=afmikKlnsStz --sort=foldcase -L - -f tags > /dev/null 2>&1"
        cscope_cmd = "cscope -q -b -U > /dev/null 2>&1"
        if only_current_file == 0
          ctags_cmd = "#{find_files_cmd(absolute_path: true)} -exec grep -Il . {} + > tags.files && ctags --fields=afmikKlnsStz --sort=foldcase -L tags.files -f tags > /dev/null 2>&1"
          cscope_cmd = "#{find_files_cmd(absolute_path: true, for_cscope: true)} -exec grep -Il . {} + > cscope.files && cscope -q -b -U > /dev/null 2>&1"
        end

        #tags
        if (@use_tags && @manage_tags)
          remove_tags_for_file($curbuf.name) if only_current_file == 1
          cmd = "#{cd_cmd} && #{ctags_cmd}"
          Juggler.logger.debug { "Updating tags with the following command: #{cmd}" }
          Juggler.refresh
          start = Time.now
          if system(cmd)
            Juggler.logger.info { "Updating tags took #{Time.now - start} seconds" }
            Juggler.refresh
          else
            Juggler.logger.error { "Error updating tags with the following command: #{cmd}" }
          end
        end

        #cscope
        if (@use_cscope && @manage_cscope)
          FileUtils.rm(Dir.glob(File.join(@indexes_path, 'cscope.*'))) if only_current_file == 0
          cmd = "#{cd_cmd} && #{cscope_cmd}"
          Juggler.logger.debug { "Updating cscope with the following command: #{cmd}" }
          Juggler.refresh
          start = Time.now
          if system(cmd)
            Juggler.logger.info { "Updating cscope took #{Time.now - start} seconds" }
            Juggler.refresh
          else
            Juggler.logger.error { "Error updating cscope with the following command: #{cmd}" }
          end
        end
        Juggler.refresh
      end
    end

    def init_completers
      @omni_completer = OmniCompleter.new if @use_omni
      @ctags_completer = CtagsCompleter.new if @use_tags
      @cscope_completer = CscopeCompleter.new(@cscope_service) if @use_cscope
      @keyword_completer = KeywordCompleter.new if @use_keyword
    end

    def generate_completions
      completion_start = Time.now
      cursor_info = VIM::evaluate('s:cursorinfo')
      token = cursor_info['token']
      Juggler.logger.info { "Generating completions for: #{token}" }

      scorer = EntryScorer.new(token, $curbuf.name, VIM::Buffer.current.line_number)
      entries = CompletionEntries.new
      completers = get_completers
      file_existence = {'' => true}

      completers.each do |completion_type, completer|
        start = Time.now
        count = 0
        completer.generate_completions(token) do |entry|
          if entry.tag != token #don't bother including exact matches
            entry_file = entry.file.to_s
            file_existence[entry_file] = File.exists?(entry_file) if file_existence[entry_file].nil?
            if file_existence[entry_file]
              entry.score = scorer.score(entry)
              entries.add(entry)
              count += 1
            else
              Juggler.logger.debug { "Skipping file because it doesn't exist: #{entry_file}" }
            end
          end
        end
        Juggler.logger.info { "#{completion_type} completions took #{Time.now - start} seconds and found #{count} entries" }
      end

      Juggler.logger.info { "#{entries.count} total entries found" }
      entries.process do |vim_arr|
        VIM::command("call extend(s:juggler_completions, #{vim_arr})")
      end
      Juggler.logger.info { "Total time was #{Time.now - completion_start}" }
    end

    protected
    def get_completers
      completers = {}
      completers[:omni] = @omni_completer if @use_omni
      completers[:tags] = @ctags_completer if @use_tags
      completers[:cscope] = @cscope_completer if @use_cscope
      completers[:keyword] = @keyword_completer if @use_keyword
      return completers
    end

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

    def find_files_cmd(absolute_path: false, for_cscope: false)
      #path_spec = absolute_path ? Shellwords.escape(VIM::evaluate('getcwd()')) : '*'
      path_spec = absolute_path ? Shellwords.escape(VIM::evaluate('getcwd()')) : '.'
      path_excludes = VIM::evaluate('g:juggler_pathExcludes')

      if for_cscope
        #cscope can't handle paths that include a space
        #if they ever fix it to handle spaces in filenames, you might have to pipe it to some sed magic like so:
        #  | sed 's/^\\(.*[ \\t].*\\)$/\"\\1\"/'"
        return "find #{path_spec} -type f -not -path " + (path_excludes + ['* *']).map {|e| Shellwords.escape(e)}.join(' -not -path ')
      else
        return "find #{path_spec} -type f -not -path " + path_excludes.map {|e| Shellwords.escape(e)}.join(' -not -path ')
      end
    end

    def remove_tags_for_file(file)
      Juggler.logger.debug { "Removing tags for file: #{file}" }
      tag_file = File.join(@indexes_path, 'tags')
      tmp_file = File.join(@indexes_path, 'tags.tmp')
      File.open(tmp_file, 'w') do |f|
        IO.foreach(tag_file) do |line|
          f.write(line) if line[0] == '!' || line.split("\t")[1] != file
        end
      end

      FileUtils.mv(tmp_file, tag_file)
    end
  end
end
