module Juggler::Plugins
  class Example < Base
    def file_opened(absolute_path)
      Juggler.logger.info { "Opened file: #{absolute_path}" }
    end
  end
end
