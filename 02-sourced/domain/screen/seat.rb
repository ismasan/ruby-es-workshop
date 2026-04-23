# frozen_string_literal: true

class Screen
  class Seat
    attr_reader :id, :status, :price_cents

    def initialize(id:, status:, price_cents:)
      @id = id
      @status = status
      @price_cents = price_cents
    end

    def available?   = status == :available
    def selected?    = status == :selected
    def unavailable? = status == :unavailable
    def accessible?  = false

    def price_display
      dollars = price_cents / 100
      cents = price_cents % 100
      cents.zero? ? "$#{dollars}" : "$#{dollars}.#{cents.to_s.rjust(2, '0')}"
    end
  end
end
