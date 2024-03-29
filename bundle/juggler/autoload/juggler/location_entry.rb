module Juggler
  class LocationEntry
    # Simple class to represent a location within a file
    attr_accessor :file # Path to file
    attr_accessor :line # Line in the file (starting from 1, not 0)
    attr_accessor :column # Column of the line (starting from 1, not 0)
    attr_accessor :description # Description of the location
    attr_accessor :additional_info # Can store arbitrary additional info of any type

    def initialize(file:, line:, column:, description:, additional_info: nil)
      self.file = File.expand_path(file)
      self.line = line
      self.column = column
      self.description = description
      self.additional_info = additional_info
    end

    def merge(other_entry)
      if column == 1 && other_entry.column > 1
        self.column = other_entry.column
      end

      if other_entry.description.size > description.size
        self.description = other_entry.description
      end
    end

    def key
      "#{file}:#{line}"
    end

    def to_s
      {file: file, line: line, column: column, description: description, additional_info: additional_info}.to_s
    end
  end
end
