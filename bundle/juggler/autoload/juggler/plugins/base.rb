require_relative '../completion_entry'

module Juggler::Plugins
  class Base
    @shared_across_filetypes = true
    class << self
      attr_reader :shared_across_filetypes
    end

    def initialize(options); end

    def file_opened(absolute_path); end
    def buffer_changed_hook(absolute_path); end
    def buffer_left_hook(absolute_path); end
    def show_references(path, line, col, term); end
    def grep(srchstr); end
  end
end
