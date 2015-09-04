require 'logger'
require_relative 'juggler/completer'

module Juggler
  def self.clean_utf8(str)
    return str.encode('UTF-8', 'UTF-8', invalid: :replace)
  end

  def self.escape_vim_singlequote_string(str)
    str.to_s.gsub("'","''")
  end

  def self.generate_scan_base_pattern(base)
    return '\b' + base.scan(/./).join('\w*') + '\w*\b' if base.length <= 2
    return '\b\w*' + base.scan(/./).join('\w*') + '\w*\b'
  end

  def self.logger
    @@logger ||= create_logger
  end

  def self.create_logger
    l = Logger.new(VimLoggerIO.new)
    l.formatter = proc { |severity, datetime, progname, msg|
      "JUGGLER #{datetime.strftime('%T.%L')} #{severity} - #{msg.to_s}"
    }
    case VIM::evaluate('g:juggler_logLevel')
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
    VIM::command("echom '#{Juggler.escape_vim_singlequote_string(msg)}'")
    return msg.to_s.length
  end
  def close; end
end
