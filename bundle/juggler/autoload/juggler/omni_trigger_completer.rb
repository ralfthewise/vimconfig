require_relative 'omni_completer'

module Juggler
  class OmniTriggerCompleter < OmniCompleter
    def generate_completions(base)
      base_regex = Regexp.new(generate_match_pattern(base), Regexp::IGNORECASE)
      super do |entry|
        yield(entry) if base_regex.match(entry.tag)
      end
    end

    protected
    def generate_match_pattern(base)
      return '\w*' + base.scan(/./).join('\w*') + '\w*'
    end
  end
end
