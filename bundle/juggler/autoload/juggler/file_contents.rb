module Juggler
  class FileContents
    def initialize
      # Keeps track of files that have been modified in vim but not yet saved to disk
      @modified_files = Set.new

      # Keeps track of a version number for each file that increments each time the file is changed
      @file_versions = Hash.new(0)
    end

    # Called to indicate that a file has been modified in vim but not yet saved to disk
    def file_modified(absolute_path)
      @modified_files.add(absolute_path)
      @file_versions[absolute_path] += 1
    end

    # Called to check if a file has been modified in vim but not yet saved to disk
    def file_modified?(absolute_path, since_version = 0)
      return false if @file_versions[absolute_path] <= since_version

      @modified_files.include?(absolute_path)
    end

    # Called to indicate that a file has been saved to disk
    def file_saved(absolute_path)
      @modified_files.delete(absolute_path)
    end

    # Returns the contents of the passed in `absolute_path` as an array of lines
    def contents_of(absolute_path)
      # TODO: maybe introduce some caching here so if called multiple times we only do this once
      if @modified_files.include?(absolute_path)
        Juggler.logger.info("Getting buffer for #{absolute_path}")
        {version: @file_versions[absolute_path], contents: VIM::evaluate("getline(1,'$')")}
      else
        {version: @file_versions[absolute_path], contents: File.readlines(absolute_path, chomp: true)}
      end
    end
  end
end
