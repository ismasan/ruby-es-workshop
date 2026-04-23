# frozen_string_literal: true

# Projector that maintains, per showing, a {seat_id => booking_id} map of held seats.
# Persists to the `seats_held` SQLite table so state survives restarts.
# Used by BookingPage to render the seat grid.
class SeatsHeld < Sourced::Projector::StateStored
  consumer_group 'seats_held'
  partition_by :showing_id

  state do |values|
    showing_id = values[:showing_id]
    held = Sourced.store.db[:seats_held]
      .where(showing_id: showing_id)
      .select_hash(:seat_id, :booking_id)
    { showing_id: showing_id, held: held }
  end

  evolve SeatSelection::SeatSelected do |state, event|
    state[:held][event.payload.seat_id] = event.payload.booking_id
  end

  evolve SeatSelection::SeatDeselected do |state, event|
    state[:held].delete(event.payload.seat_id)
  end

  sync do |state:, **|
    db = Sourced.store.db
    showing_id = state[:showing_id]
    db[:seats_held].where(showing_id: showing_id).delete
    rows = state[:held].map { |seat_id, booking_id| { showing_id: showing_id, seat_id: seat_id, booking_id: booking_id } }
    db[:seats_held].multi_insert(rows) unless rows.empty?
  end

  Updated = Sourced::Event.define('system.seats_held.updated') do
    attribute :showing_id, String
  end

  after_sync do |state:, **|
    Sidereal.pubsub.publish('system', Updated.new(payload: { showing_id: state[:showing_id] }))
  end

  def self.for_showing(showing_id)
    Sourced.store.db[:seats_held]
      .where(showing_id: showing_id)
      .select_hash(:seat_id, :booking_id)
  end

  def self.on_reset
    Sourced.store.db[:seats_held].delete
  end
end
