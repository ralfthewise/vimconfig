module Juggler
  class ScoredLocationEntry
    # Simple class to wrap a LocationEntry and allow scoring it
    extend Forwardable
    def_delegators :entry, *Juggler::LocationEntry.public_instance_methods(false)

    attr_reader :entry

    def initialize(entry, scorer)
      self.entry = entry
      self.scorer = scorer
    end

    def score
      return @score if @score

      @score = scorer.score(entry)
    end
  end
end
