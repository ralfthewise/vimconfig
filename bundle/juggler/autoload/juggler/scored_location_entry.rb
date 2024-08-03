module Juggler
  class ScoredLocationEntry
    # Simple class to wrap a LocationEntry and allow scoring it
    extend Forwardable
    def_delegators :entry, *Juggler::LocationEntry.public_instance_methods(false)

    attr_reader :entry

    def initialize(entry, scorer)
      @entry = entry
      @scorer = scorer
    end

    def score
      return @score if @score

      @score = @scorer.score(@entry)
    end

    def pretty_log(indent = 0)
      "#{' ' * indent}Score: #{score[:score]}\n#{@entry.pretty_log(indent)}\n#{' ' * indent}Score Data:\n" +
        score[:match_data].map {|md| "#{' ' * (indent + 2)}#{md}"}.join("\n")
    end
  end
end
