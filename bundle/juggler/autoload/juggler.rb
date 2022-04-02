require 'logger'
require_relative 'juggler/completer'

module Juggler
  def self.clean_utf8(str)
    return str.encode('UTF-8', 'UTF-8', invalid: :replace)
  end

  def self.escape_vim_singlequote_string(str)
    #replace:
    # \0 with (nothing/empty string)
    # ' with ''
    return str.to_s.gsub(/[\0']/, {"\0" => '', "'" => "''"})
  end

  def self.escape_vim_doublequote_string(str)
    #replace:
    # \ with \\
    # " with \"
    # | with \|
    str = str.to_s.gsub(/[\\"|]/, {'\\' => '\\\\', '"' => '\\"', '|' => '\\|'})
    #replace all newline character sequences with \n - NOTE we are replacing it with the string "\\n", NOT the newline character
    return str.gsub("\r\n", '\\n').gsub(/[\r\n]/, '\\n')
  end

  def self.generate_scan_base_pattern(base)
    return base.scan(/./).join('\w*') + '\w*' if base.length <= 2
    return '\w*' + base.scan(/./).join('\w*') + '\w*'
  end

  def self.logger
    @@logger ||= create_logger
  end

  def self.refresh
    VIM::command('redraw!|redrawstatus')
  end

  def self.with_status(line)
    VIM::command("let s:oldstatusline = &statusline | set statusline=#{line.to_s.gsub(' ', '\\ ')} | redrawstatus")
    begin
      yield
    ensure
      VIM::command('let &statusline = s:oldstatusline | redrawstatus')
    end
  end

  def self.create_logger
    l = (ENV['JUGGLER_LOG_FILE'] ? Logger.new(ENV['JUGGLER_LOG_FILE']) : Logger.new(VimLoggerIO.new))
    l.formatter = proc { |severity, datetime, progname, msg|
      "JUGGLER #{datetime.strftime('%T.%L')} ##{Thread.current.object_id} #{severity} - #{msg.to_s}\n"
    }
    case (ENV['JUGGLER_LOG_LEVEL'] || VIM::evaluate('g:juggler_logLevel'))
    when 'warn' then l.level = Logger::WARN
    when 'info' then l.level = Logger::INFO
    when 'debug' then l.level = Logger::DEBUG
    else l.level = Logger::ERROR
    end
    return l
  end
end

class VimLoggerIO
  def write(msg)
    msg.split("\n").each {|line| VIM::command("echom '#{Juggler.escape_vim_singlequote_string(line)}'")}
    return msg.length
  end
  def close; end
end
