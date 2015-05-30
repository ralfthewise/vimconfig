require_relative 'juggler/completer'

module Juggler
  def self.escape_vim_singlequote_string(str)
    str.to_s.gsub("'","''")
  end

  def self.generate_scan_base_pattern(base)
    return '\b\w*' + base.scan(/./).join('\w*') + '\w*\b'
  end
end
