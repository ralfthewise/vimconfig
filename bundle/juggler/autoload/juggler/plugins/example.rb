module Juggler::Plugins
  class Example < Base
    def initialize(project_dir:, **opts)
      super

      logger.info { "`Example` plugin initialized with project_dir `#{project_dir}` and options `#{opts}`" }
    end

    def file_opened(absolute_path)
      logger.info { "file_opened: #{absolute_path}" }
    end

    def show_references(path, line, col, term)
      logger.info { "show_references:\n  path: #{path}\n  line: #{line}\n  col: #{col}\n  term: #{term}" }
    end

    def grep(srchstr)
      logger.info { "grep: #{srchstr}" }
    end

    def generate_completions(base, cursor_info)
      logger.info { "generate_completions:\n  base: #{base}\n  cursor_info: #{cursor_info}" }
    end

    # Hooks
    def buffer_changed_hook(absolute_path)
      logger.info { "buffer_changed_hook: #{absolute_path}" }
    end

    def buffer_left_hook(absolute_path)
      logger.info { "buffer_left_hook: #{absolute_path}" }
    end
  end
end
