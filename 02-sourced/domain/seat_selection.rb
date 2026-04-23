# frozen_string_literal: true

# Per-seat decider: validates seat selection for a single (showing_id, seat_id) pair.
# State is tiny and isolated — which booking currently holds this seat.
class SeatSelection < Sourced::Decider
  consumer_group 'seat_selection'
  partition_by :showing_id, :seat_id

  Select = Sourced::Command.define('seats.select') do
    attribute :showing_id, Types::String.present
    attribute :seat_id, Types::String.present
    attribute :booking_id, Types::String.present
  end

  SeatSelected = Sourced::Event.define('seats.selected') do
    attribute :showing_id, String
    attribute :seat_id, String
    attribute :booking_id, String
    attribute :price_cents, Integer
  end

  Deselect = Sourced::Command.define('seats.deselect') do
    attribute :showing_id, Types::String.present
    attribute :seat_id, Types::String.present
    attribute :booking_id, Types::String.present
  end

  SeatDeselected = Sourced::Event.define('seats.deselected') do
    attribute :showing_id, String
    attribute :seat_id, String
    attribute :booking_id, String
  end

  state do |values|
    { showing_id: values[:showing_id], seat_id: values[:seat_id], held_by: nil }
  end

  evolve SeatSelected do |state, event|
    state[:held_by] = event.payload.booking_id
  end

  evolve SeatDeselected do |state, _event|
    state[:held_by] = nil
  end

  command Select do |state, cmd|
    booking_id = cmd.payload.booking_id

    if state[:held_by] == booking_id
      # already ours — no-op
    elsif state[:held_by]
      raise "Seat '#{cmd.payload.seat_id}' is already taken for this showing"
    else
      showing = Catalog.find_showing(cmd.payload.showing_id)
      raise "Unknown showing '#{cmd.payload.showing_id}'" unless showing

      template = Catalog.screen_template(showing.screen_id)
      row_label = cmd.payload.seat_id[0]
      row = template[:rows].find { |r| r[:label] == row_label }
      num = cmd.payload.seat_id[1..].to_i
      raise "Seat '#{cmd.payload.seat_id}' does not exist in screen '#{showing.screen_id}'" unless row && num.between?(1, row[:seats])

      event SeatSelected,
        showing_id: cmd.payload.showing_id,
        seat_id: cmd.payload.seat_id,
        booking_id: booking_id,
        price_cents: row[:seat_price]
    end
  end

  command Deselect do |state, cmd|
    event SeatDeselected, cmd.payload if state[:held_by] == cmd.payload.booking_id
  end

  Updated = Sourced::Event.define('system.seats.updated') do
    attribute :showing_id, String
    attribute :seat_id, String
  end

  after_sync do |state:, **|
    Sidereal.pubsub.publish('system', Updated.new(payload: state.slice(:showing_id, :seat_id)))
  end
end
