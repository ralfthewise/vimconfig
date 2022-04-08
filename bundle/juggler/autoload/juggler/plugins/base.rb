require_relative '../completion_entry'

module Juggler::Plugins
  class Base
    @shared_across_filetypes = true
    class << self
      attr_reader :shared_across_filetypes
    end

    def initialize(options); end

    def file_opened(absolute_path); end
    def show_references(path, line, col); end
  end
end
