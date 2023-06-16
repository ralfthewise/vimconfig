require_relative '../completion_entry'

module Juggler::Plugins
  class OmniCompleter < Base
    def generate_completions(_absolute_path, base, cursor_info)
      omni_results = VIM::evaluate('s:CallOmniFunc()')
      if omni_results.is_a?(Array)
        omni_results.each do |omni_result|
          next if omni_result['word'] == base
          entry = Juggler::CompletionEntry.new(source: :omni, tag: omni_result['word'], signature: (omni_result['abbr'] || omni_result['info']), info: omni_result['info'])
          yield(entry)
        end
      end
    end
  end
end
