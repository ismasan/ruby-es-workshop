# frozen_string_literal: true

require 'pstore'

# File-backed event store using Ruby's PStore. Events survive across
# processes as long as the same file path is used.
#
# @example Append events and read them back
#   store = FSStore.new('events.pstore')
#   store.append('bookings/42', BookingStarted.new(booking_id: 42, showing_id: 1, timestamp: Time.now))
#   store.append('bookings/42', SeatBooked.new(booking_id: 42, seat_id: 'A1', timestamp: Time.now))
#   store.read('bookings/42') # => [#<BookingStarted ...>, #<SeatBooked ...>]
#
# @example Events persist across instances on the same path
#   FSStore.new('events.pstore').append('s1', :e1)
#   FSStore.new('events.pstore').read('s1') # => [:e1]
#
# @example append returns the new stream version
#   store = FSStore.new('events.pstore')
#   store.append('s1', :e1) # => 1
#   store.append('s1', :e2) # => 2
class FSStore
  # @param path [String] filesystem path for the PStore file
  def initialize(path = 'events.pstore')
    @store = PStore.new(path)
  end

  # Append an event to a stream. Wrapped in a PStore read-write transaction.
  #
  # @param stream_id [String] the stream identifier
  # @param event [Object] any Marshal-serialisable event object
  # @return [Integer] the new stream size (version)
  def append(stream_id, event)
    @store.transaction do
      @store[stream_id] ||= []
      @store[stream_id] << event
      @store[stream_id].size
    end
  end

  # Read all events for a stream. Wrapped in a read-only PStore transaction.
  #
  # @param stream_id [String] the stream identifier
  # @return [Array<Object>] the events in append order (empty if the stream is unknown)
  def read(stream_id)
    @store.transaction(true) do
      @store[stream_id] || []
    end
  end
end
