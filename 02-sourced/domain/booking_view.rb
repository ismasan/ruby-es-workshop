# frozen_string_literal: true

# In-memory projection for the booking page.
#
# Reads events for one showing using AND-filtered partition reads, then
# evolves them into a {seat_id => booking_id} map. Not registered with
# Sourced and has no `sync` block, so no worker runs and no state is
# persisted — built on demand via `Sourced.load(BookingView, showing_id:)`.
# Pass `upto:` (a global event position) to time-travel to a previous state.
class BookingView < Sourced::Projector::EventSourced
  partition_by :showing_id

  state do |values|
    { showing_id: values[:showing_id], held: {} }
  end

  evolve SeatSelection::SeatSelected do |state, event|
    state[:held][event.payload.seat_id] = event.payload.booking_id
  end

  evolve SeatSelection::SeatDeselected do |state, event|
    state[:held].delete(event.payload.seat_id)
  end
end
