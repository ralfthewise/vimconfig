require 'fileutils'
require 'singleton'
require 'shellwords'
require 'digest/sha1'
require_relative 'cscope_service'
require_relative 'entry_scorer'
require_relative 'completion_entries'
require_relative 'plugins'
require_relative 'plugins/base'
require_relative 'plugins/omni_completer'
require_relative 'plugins/caching_omni_completer'
require_relative 'plugins/ctags'
require_relative 'plugins/cscope'
require_relative 'plugins/keywords'
require_relative 'plugins/lsp'

module Juggler
  class Completer
    include Singleton

    attr_accessor :file_contents

    def initialize
      @file_contents = FileContents.new
      @log_level = ENV['JUGGLER_LOG_LEVEL'] || VIM::evaluate('g:juggler_logLevel')
      #TODO: load these on each completion
      @use_omni = VIM::evaluate('g:juggler_useOmniCompleter') == 1
      @use_omni_trigger = VIM::evaluate('g:juggler_useOmniTrigger') == 1
      @use_omni_trigger_cache = VIM::evaluate('g:juggler_useOmniTriggerCache') == 1
      @use_tags = VIM::evaluate('g:juggler_useTagsCompleter') == 1
      @manage_tags = VIM::evaluate('g:juggler_manageTags') == 1
      @use_cscope = VIM::evaluate('g:juggler_useCscopeCompleter') == 1
      @manage_cscope = VIM::evaluate('g:juggler_manageCscope') == 1
      @use_keyword = VIM::evaluate('g:juggler_useKeywordCompleter') == 1
      @use_lsp = VIM::evaluate('g:juggler_useLSPCompleter') == 1
      @language_plugins_config = VIM::evaluate('g:juggler_language_plugins')

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

    def indexes_path
      @indexes_path
    end

    def replace_ctrlp_user_command
      VIM::command("let g:ctrlp_user_command = '#{Juggler::escape_vim_singlequote_string(find_files_cmd(for_path: '%s'))}'")
    end

    def find
      Juggler.with_status('Searching...') do
        srchstr = VIM::evaluate('srchstr').to_s
        next if srchstr == ''

        Juggler.logger.debug { "Starting search for pattern: #{srchstr}\n" }

        result = []
        plugins.each do |p|
          plugin_results = p.grep(srchstr)
          result += plugin_results.to_a
        end
        Juggler.logger.debug do
          "Completed search for pattern: #{srchstr}\n" +
          "  Num results: #{result.length}\n" +
          "  Final results:\n#{result.join("\n")}"
        end
        result = result.map {|entry| "\"#{Juggler.escape_vim_doublequote_string(entry.strip[0..191])}\""}.join(',')
        # TODO: consider this instead?
        #   call setqflist([{'filename':'foo','lnum':23,'col':4,'text':'some helpful text'},{'filename':'blah/blab.txt','lnum':23,'col':43,'text':'other text'}], 'r')
        VIM::command("cgetexpr [#{result}]")

        #VIM::command("cgetexpr split(\"#{Juggler.escape_vim_doublequote_string(result)}\", \"\\n\")")
        #VIM::command("cgetexpr system('#{Juggler.escape_vim_singlequote_string(grep_cmd)} \\| #{Juggler.escape_vim_singlequote_string(strip_tabs_cmd)}')")

        VIM::command('copen')
        Juggler.refresh
      end
    end

    def show_references
      Juggler.with_status('Finding references...') do
        term = VIM::evaluate('resolvedterm').to_s
        next if term == ''

        Juggler.logger.debug { "Searching for references of: #{term}" }
        result = []
        _bufnum, lnum, col, _off = VIM::evaluate('getpos(".")')
        plugins.each do |p|
          plugin_results = p.show_references(eval_current_path, lnum - 1, col - 1, term)
          Juggler.logger.debug { "Plugin results (#{p.class.to_s}): #{plugin_results}" }
          result += plugin_results.to_a
        end
        result.map! do |entry|
          kind = entry[:kind].to_s.strip.empty? ? '' : "<#{entry[:kind].to_s.strip}> "
          qfix_entry = "#{entry[:file]}:#{entry[:line]}: #{kind}#{entry[:tag_line]}"
          "\"#{Juggler.escape_vim_doublequote_string(qfix_entry.strip[0..191])}\""
        end
        VIM::command("cgetexpr [#{result.join(',')}]")
        VIM::command('copen')
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
      # @omni_completer = Plugins::OmniCompleter.new if @use_omni
      # @omni_trigger_completer = Plugins::CachingOmniCompleter.new(@use_omni_trigger_cache) if @use_omni_trigger
      # @ctags_completer = Plugins::Ctags.new if @use_tags
      # @cscope_completer = Plugins::Cscope.new(@cscope_service) if @use_cscope
      # @keyword_completer = Plugins::Keywords.new if @use_keyword
      # @lsp_completer = Plugins::Lsp.new(root_path: '.', cmd: "bash -l -c #{Shellwords.escape('bundle exec solargraph socket')}", host: '127.0.0.1', logger: Juggler.logger) if @use_lsp
    end

    def generate_completions
      begin
        completion_start = Time.now
        cursor_info = VIM::evaluate('s:cursorinfo')
        token = cursor_info['token']
        Juggler.logger.info { "Generating completions for: #{token} (#{cursor_info})" }

        scorer = EntryScorer.new(token, $curbuf.name, VIM::Buffer.current.line_number)
        entries = CompletionEntries.new
        completers = get_completers(cursor_info)
        file_existence = {'' => true}

        plugins.each do |plugin|
          start = Time.now
          count = 0
          plugin.generate_completions(token, cursor_info) do |entry|
            if entry.tag != token #don't bother including exact matches
              entry_file = entry.file.to_s
              file_existence[entry_file] = File.exists?(entry_file) if file_existence[entry_file].nil?
              if file_existence[entry_file]
                entry.score_data = scorer.score(entry)
                entries.add(entry)
                count += 1
              else
                Juggler.logger.debug { "Skipping file because it doesn't exist: #{entry_file}" }
              end
            end
          end
          Juggler.logger.info { "#{plugin.class.to_s} completions took #{Time.now - start} seconds and found #{count} entries" }
        end

        # completers.each do |completion_type, completer|
        #   start = Time.now
        #   count = 0
        #   completer.generate_completions(token, cursor_info) do |entry|
        #     if entry.tag != token #don't bother including exact matches
        #       entry_file = entry.file.to_s
        #       file_existence[entry_file] = File.exists?(entry_file) if file_existence[entry_file].nil?
        #       if file_existence[entry_file]
        #         entry.score_data = scorer.score(entry)
        #         entries.add(entry)
        #         count += 1
        #       else
        #         Juggler.logger.debug { "Skipping file because it doesn't exist: #{entry_file}" }
        #       end
        #     end
        #   end
        #   Juggler.logger.info { "#{completion_type} completions took #{Time.now - start} seconds and found #{count} entries" }
        # end

        Juggler.logger.info { "#{entries.count} total entries found" }
        entries.process do |vim_arr|
          VIM::command("call extend(s:juggler_completions, #{vim_arr})")
        end
        Juggler.logger.info { "Total time was #{Time.now - completion_start}" }
      rescue Exception => e
        Juggler.logger.error { "Exception while generating completions: #{e}\n#{e.backtrace.join("\n")}" }
      end
    end

    def sum_block
      block = VIM::evaluate('s:juggler_sum_block').to_s
      #Juggler.logger.info { "Sum block on:\n#{block}" }
      items = block.split(/\s/).reject {|e| e.to_s.empty?}.map do |e|
        !!(e =~ /\A[-+]?\d+\z/) ? e.to_i : e.to_f
      end
      VIM::command("let s:juggler_sum_block = '#{items.reduce(:+)}'")
    end

    def file_opened_hook
      absolute_path = eval_current_path
      return unless File.file?(absolute_path)

      Juggler.logger.info { "File loaded: #{absolute_path}" }
      plugins.each {|p| p.file_opened(absolute_path)}
    end

    def file_saved_hook
      absolute_path = eval_current_path
      Juggler.logger.info { "File saved: #{absolute_path}" }

      @file_contents.file_saved(absolute_path)
    end

    def buffer_changed_hook
      absolute_path = eval_current_path
      return unless File.file?(absolute_path)

      @file_contents.file_modified(absolute_path)
      Juggler.logger.info { "Buffer changed: #{absolute_path}" }
      plugins.each {|p| p.buffer_changed_hook(absolute_path)}
    end

    def buffer_left_hook
      absolute_path = eval_current_path
      return unless File.file?(absolute_path)

      Juggler.logger.info { "Buffer left: #{absolute_path}" }
      plugins.each {|p| p.buffer_left_hook(absolute_path)}
    end

    protected

    # Gets the plugins for the current filetype
    def plugins
      plugins_for_filetype(VIM::evaluate('&filetype'))
    end

    def plugins_for_filetype(filetype)
      Juggler.logger.debug { "Language plugins config: #{@language_plugins_config}" } if @plugins.nil?

      @plugins ||= {}
      return @plugins[filetype] if @plugins.key?(filetype)

      # If there's no specific config for this filetype, just use the wildcard one
      if !@language_plugins_config.key?(filetype)
        @plugins[filetype] = plugins_for_filetype('*')
        return @plugins[filetype]
      end

      @plugins[filetype] = []
      @language_plugins_config[filetype].to_a.each do |plugin_config|
        if plugin_config.is_a?(String)
          if plugin_config == '*'
            raise "Can't have nested wildcard '*' configs" if filetype == '*'

            @plugins[filetype] += plugins_for_filetype('*')
          else
            @plugins[filetype] << Juggler::Plugins.load_plugin(plugin_config, default_plugin_options)
          end
        else
          plugin_config.each do |plugin_name, options|
            @plugins[filetype] << Juggler::Plugins.load_plugin(plugin_name, default_plugin_options.merge(options))
          end
        end
      end

      Juggler.logger.debug { "Plugins for filetype `#{filetype}`:\n  #{@plugins[filetype].map(&:for_display).join("\n  ")}" }
      @plugins[filetype]
    end

    def default_plugin_options
      @default_plugin_options ||= {
        project_dir: determine_project_dir,
        current_file: File.absolute_path(VIM::evaluate('bufname("%")')),
        logger: Juggler.logger,
      }
    end

    def eval_current_path
      File.expand_path(VIM::evaluate('expand("%:p")'))
    end

    def get_completers(cursor_info)
      return {omni_trigger: @omni_trigger_completer} if @use_omni_trigger && cursor_info['type'] == 'omnitrigger'

      completers = {}
      completers[:omni] = @omni_completer if @use_omni
      completers[:omnitrigger] = @omni_trigger_completer if @use_omni_trigger
      completers[:tags] = @ctags_completer if @use_tags
      completers[:cscope] = @cscope_completer if @use_cscope
      completers[:keyword] = @keyword_completer if @use_keyword
      return completers
    end

    def determine_project_dir
      cwd = VIM::evaluate('getcwd()')
      buf = File.absolute_path(VIM::evaluate('bufname("%")'))
      buf_wd = File.expand_path('..', buf)
      result = Juggler.walk_tree_looking_for_files(cwd)
      result = Juggler.walk_tree_looking_for_files(buf_wd) if result.nil?
      return result
    end

    def find_files_cmd(for_path: nil, absolute_path: false, for_cscope: false)
      path_spec = for_path
      if path_spec.nil?
        #path_spec = absolute_path ? Shellwords.escape(VIM::evaluate('getcwd()')) : '*'
        path_spec = absolute_path ? Shellwords.escape(VIM::evaluate('getcwd()')) : '.'
      end
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
          f.write(line) if line[0] == '!' || (line.valid_encoding? && line.split("\t")[1] != file)
        end
      end

      FileUtils.mv(tmp_file, tag_file)
    end
  end
end
