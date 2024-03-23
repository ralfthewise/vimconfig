module Juggler::Plugins
  class Example < Base
    def initialize(project_dir:, **opts)
      super

      logger.info { "`Example` plugin initialized with project_dir `#{project_dir}` and options `#{opts}`" }
    end

    def file_opened(absolute_path)
      logger.info { "file_opened: #{absolute_path}" }
    end

    def go_to_definition(path, line, col, term)
      logger.info { "go_to_definition:\n  path: #{path}\n  line: #{line}\n  col: #{col}\n  term: #{term}" }
      []
    end

    def show_references(path, line, col, term)
      logger.info { "show_references:\n  path: #{path}\n  line: #{line}\n  col: #{col}\n  term: #{term}" }
      []
    end

    def grep(srchstr)
      logger.info { "grep: #{srchstr}" }
      []
    end

    # Params if the word leading up to the cursor is `col`
    #   absolute_path: "<absolute path to file currently open>"
    #   base: "col"
    #   cursor_info: {"token"=>"col", "cursorindex"=>46, "match"=>1, "matchstart"=>43, "type"=>"token", "base"=>"col", "linenum"=>194}
    #
    # Should yield a CompletionEntry for every match:
    #   yield Juggler::CompletionEntry.new(source: :keyword, index: index, file: file, line: line_num, tag: tag)
    def generate_completions(absolute_path, base, cursor_info)
      # logger.info { "generate_completions:\n  absolute_path: #{absolute_path}\n  base: #{base}\n  cursor_info: #{cursor_info}\n  contents: #{Juggler.file_contents(absolute_path)}" }
      logger.info { "generate_completions:\n  absolute_path: #{absolute_path}\n  base: #{base}\n  cursor_info: #{cursor_info}" }
    end

    # Hooks
    def buffer_changed_hook(absolute_path)
      # logger.info { "buffer_changed_hook: #{absolute_path}\n#{Juggler.file_contents(absolute_path)}" }
      logger.info { "buffer_changed_hook: #{absolute_path}" }
    end

    def buffer_left_hook(absolute_path)
      logger.info { "buffer_left_hook: #{absolute_path}" }
    end
  end
end
