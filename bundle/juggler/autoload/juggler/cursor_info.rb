module Juggler
  class CursorInfo < LocationEntry
    # Simple class to represent cursor information. Same as a LocationEntry but
    # `line` and `column` are required.
    #
    # Normally the `column` field starts from 1, but if you are in edit mode at
    # the very beginning of the line it will actually be 0 in a CursofInfo
    # object.

    def initialize(file:, line:, column:)
      super
    end

    def inspect
      to_h.to_s
    end
  end
end
