# frozen_string_literal: true

class Screen
  attr_reader :name, :rows

  # Build a fresh Screen from a template hash + a map of held seats.
  # `held` is {seat_id => booking_id}. The `current_booking_id` determines
  # whether a held seat is rendered as :selected (ours) or :unavailable (theirs).
  def self.from_template(template, held: {}, current_booking_id: nil)
    rows = template[:rows].map do |row_hash|
      seats = (1..row_hash[:seats]).map do |i|
        seat_id = "#{row_hash[:label]}#{i}"
        holder = held[seat_id]
        status =
          if holder.nil?
            :available
          elsif holder == current_booking_id
            :selected
          else
            :unavailable
          end
        Seat.new(id: seat_id, status: status, price_cents: row_hash[:seat_price])
      end
      Row.new(label: row_hash[:label], aisle_after: row_hash[:aisle_after], seats: seats)
    end
    new(name: template[:name], rows: rows)
  end

  def initialize(name:, rows: [])
    @name = name
    @rows = rows
    @seats_index = rows.each_with_object({}) do |row, idx|
      row.seats.each { |seat| idx[seat.id] = seat }
    end
  end

  def [](seat_id)
    @seats_index[seat_id]
  end

  def selected_seats
    @seats_index.values.select(&:selected?)
  end
end
