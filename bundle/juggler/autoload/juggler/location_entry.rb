module Juggler
  class LocationEntry
    # Simple class to represent a location within a file
    attr_accessor :file # Absolute path to file
    attr_accessor :line # Line in the file (starting from 1, not 0)
    attr_accessor :column # Column of the line (starting from 1, not 0)
    attr_accessor :description # Description of the location
    attr_accessor :source # Source (plugin that created this entry) of this LocationEntry - can be an array if multiple plugins create identical LocationEntrys

    def initialize(file:, line: nil, column: nil, description: nil, source: nil)
      self.file = File.expand_path(file)
      self.line = line
      self.column = column
      self.description = description
      self.source = [source] unless source.nil?
    end

    def merge(other_entry)
      if column.to_i == 0 && other_entry.column.to_i > 0
        self.column = other_entry.column
      end

      if other_entry.description.size > description.size
        self.description = other_entry.description
      end

      self.source += other_entry.source
    end

    def key
      "#{file}:#{line}"
    end

    # Produce an object that can be consumed by vim's quickfix, see `:help setqflist-what`
    def to_vim_quickfix
      {filename: file, lnum: line, col: (column.nil? ? 1 : column), vcol: 1, text: description.strip[0..164]}
    end

    def pretty_log(indent = 0)
      to_h.map do |k, v|
        "#{' ' * indent}#{k}: #{v}"
      end.join("\n")
    end

    def to_h
      {Source: source, File: file, Line: line, Column: column, Description: description}.compact
    end
  end
end
