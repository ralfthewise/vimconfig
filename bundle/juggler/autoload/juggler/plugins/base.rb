require_relative '../completion_entry'

module Juggler::Plugins
  class Base
    @shared_across_filetypes = true
    class << self
      attr_reader :shared_across_filetypes
    end

    attr_accessor :logger, :options

    def initialize(logger: Logger.new($stdout, level: Logger::INFO), **options)
      @logger = logger.clone

      if @logger.formatter
        original_formatter = @logger.formatter.dup
        @logger.formatter = proc { |severity, datetime, progname, msg|
          original_formatter.call(severity, datetime, progname, "#{self.class} - #{msg.to_s}") # Include the class name in log output
        }
      else
        @logger.formatter = proc { |severity, datetime, progname, msg|
          "#{self.class} - #{msg.to_s}"
        }
      end

      @options = options
    end

    def file_opened(absolute_path); end
    def buffer_changed_hook(absolute_path); end
    def buffer_left_hook(absolute_path); end

    # Should return an array of objects with the following properties:
    #   file: path to file (relative to project root)
    #   line: line in the file (starting from 1, not 0)
    #   col: column of the line (starting from 1, not 0)
    #   desc: description to display
    def go_to_definition(path, line, col, term); end

    def show_references(path, line, col, term); end
    def grep(srchstr); end
    def generate_completions(absolute_path, base, cursor_info); end

    def for_display
      "#{Juggler::Utils::Colorize.bold(self.class)}: #{@options}"
    end
  end
end
