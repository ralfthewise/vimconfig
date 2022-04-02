require_relative '../completion_entry'

module Juggler::Completers
  class BaseCompleter
    def file_opened(absolute_path); end
    def show_references(path, line, col); end
  end
end
