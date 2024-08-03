# Some monkey patches we apply to the `VIM` module
module VIM
  # Passing args from ruby to vim functions is a little tricky. I haven't found
  # a better way to do it than this, where we convert it to JSON in ruby and
  # then decode the JSON in vimscript.
  #
  # Here is an example of how to use it. Imagine that you have a ruby Hash that
  # you want to pass to a vimscript function. From the ruby code, you would
  # call:
  #   VIM::evaluate("setqflist(#{VIM::arg(my_hash)}, 'r')")
  def self.arg(arg)
    "json_decode('#{escape_singlequote_string(arg.to_json)}')"
  end

  def self.cursor_info
    _bufnum, line, column = VIM::evaluate('getcursorcharpos()')
    Juggler::CursorInfo.new(file: current_absolute_path, line: line, column: column)
  end

  def self.current_absolute_path
    File.expand_path(VIM::evaluate('expand("%:p")'))
  end

  # "\0" is a null byte
  # (https://www.thehacker.recipes/web/inputs/null-byte-injection) which ruby
  # supports, but could be problematic passing back up to vim which is mostly
  # written in C.
  def self.escape_doublequote_string(str)
    # Replace:
    #   \0 with (nothing/empty string)
    #   \ with \\
    #   " with \"
    #   | with \|
    str = str.to_s.gsub(/[\0\\"|]/, {"\0" => '', '\\' => '\\\\', '"' => '\\"', '|' => '\\|'})

    # Replace all newline character sequences with \n - NOTE we are replacing
    # it with the string "\\n", NOT the newline character
    return str.gsub("\r\n", '\\n').gsub(/[\r\n]/, '\\n')
  end

  def self.escape_singlequote_string(str)
    # replace:
    #   \0 with (nothing/empty string)
    #   ' with ''
    return str.to_s.gsub(/[\0']/, {"\0" => '', "'" => "''"})
  end

  # Same as `VIM::command`, but first logs what will be executed
  def self.log_cmd(cmd)
    Juggler.logger.debug {"VIM::command - #{cmd}"}
    VIM::command(cmd)
  end
end
