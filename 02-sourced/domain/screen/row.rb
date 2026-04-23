# frozen_string_literal: true

class Screen
  class Row
    attr_reader :label, :seats, :aisle_after

    def initialize(label:, seats:, aisle_after:)
      @label = label
      @seats = seats
      @aisle_after = aisle_after
    end
  end
end
