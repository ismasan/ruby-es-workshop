# frozen_string_literal: true

# In-memory event store. Events are kept in a Hash keyed by stream id
# and are lost when the process exits.
#
# @example Append events and read them back
#   store = MemStore.new
#   store.append('bookings/42', BookingStarted.new(booking_id: 42, showing_id: 1, timestamp: Time.now))
#   store.append('bookings/42', SeatBooked.new(booking_id: 42, seat_id: 'A1', timestamp: Time.now))
#   store.read('bookings/42') # => [#<BookingStarted ...>, #<SeatBooked ...>]
#
# @example append returns the new stream version
#   store = MemStore.new
#   store.append('s1', :e1) # => 1
#   store.append('s1', :e2) # => 2
#
# @example Unknown streams read as an empty array
#   MemStore.new.read('missing') # => []
class MemStore
  def initialize
    @log = Hash.new { |h, k| h[k] = [] }
  end

  # Append an event to a stream.
  #
  # @param stream_id [String] the stream identifier
  # @param event [Object] any event object
  # @return [Integer] the new stream size (version)
  def append(stream_id, event)
    @log[stream_id] << event

    @log[stream_id].size
  end

  # Read all events for a stream.
  #
  # @param stream_id [String] the stream identifier
  # @return [Array<Object>] the events in append order (empty if the stream is unknown)
  def read(stream_id)
    @log[stream_id]
  end
end
