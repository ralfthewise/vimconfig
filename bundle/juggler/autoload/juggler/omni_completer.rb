require_relative 'completion_entry'

module Juggler
  class OmniCompleter
    def generate_completions(base)
      omni_results = VIM::evaluate('s:CallOmniFunc()')
      if omni_results.is_a?(Array)
        omni_results.each do |omni_result|
          next if omni_result['word'] == base
          entry = CompletionEntry.new(source: :omni, tag: omni_result['word'], signature: (omni_result['abbr'] || omni_result['info']), info: omni_result['info'])
          yield(entry)
        end
      end
    end
  end
end
