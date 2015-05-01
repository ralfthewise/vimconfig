require_relative 'completion_entry'

module Juggler
  class OmniCompleter
    def generate_completions
      omni_results = VIM::evaluate('s:CallOmniFunc()')
      omni_results.each do |omni_result|
        entry = CompletionEntry.new(source: :omni, tag: omni_result['word'], signature: (omni_result['abbr'] || omni_result['info']), info: omni_result['info'])
        yield(entry)
      end
    end
  end
end
