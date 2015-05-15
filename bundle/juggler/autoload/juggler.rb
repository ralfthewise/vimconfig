require_relative 'juggler/completer'

module Juggler
  def self.escape_vim_singlequote_string(str)
    str.to_s.gsub("'","''")
  end
end
