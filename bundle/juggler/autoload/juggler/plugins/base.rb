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

    # Should return an array of Juggler::LocationEntrys
    def go_to_definition(cursor_info, term); end
    def show_references(cursor_info, term); end

    def grep(srchstr); end

    # Should return a Juggler::LocationEntryCollection
    def find_files(cursor_info, srchstr); end
    def find_tags(cursor_info, srchstr); end

    def generate_completions(absolute_path, base, cursor_info); end
    def update_indexes(only_current_file: false); end

    def for_display
      "#{Juggler::Utils::Colorize.bold(self.class)}: #{@options}"
    end
  end
end
