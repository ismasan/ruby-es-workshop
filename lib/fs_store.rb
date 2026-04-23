# frozen_string_literal: true

require 'pstore'
require 'fileutils'
require_relative 'subscriptions'

# File-backed event store using Ruby's PStore. Events survive across
# processes as long as the same directory is used.
#
# @example Append events and read them back
#   store = FSStore.new('store')
#   store.append('bookings/42', BookingStarted.new(booking_id: 42, showing_id: 1, timestamp: Time.now))
#   store.append('bookings/42', SeatBooked.new(booking_id: 42, seat_id: 'A1', timestamp: Time.now))
#   store.read('bookings/42') # => [#<BookingStarted ...>, #<SeatBooked ...>]
#
# @example Events persist across instances on the same directory
#   FSStore.new('store').append('s1', :e1)
#   FSStore.new('store').read('s1') # => [:e1]
#
# @example append returns the new stream version
#   store = FSStore.new('store')
#   store.append('s1', :e1) # => 1
#   store.append('s1', :e2) # => 2
#
# @example Subscribe with a polling worker that tracks per-stream offsets
#   store = FSStore.new('store')
#   thread = store.subscribe('projector') do |stream_id, event|
#     puts "#{stream_id}: #{event.inspect}"
#   end
#   # ...later
#   thread.kill
class FSStore
  attr_reader :subscriptions

  # @param dir [String] directory to hold the PStore file (created if missing)
  def initialize(dir = 'store')
    FileUtils.mkdir_p(dir)
    @store = PStore.new(File.join(dir, 'events.pstore'), true)
    @store.transaction do
      @store[:streams] ||= {}
    end
    @subscriptions = Subscriptions.new(@store)
  end

  # Append an event to a stream. Wrapped in a PStore read-write transaction.
  #
  # @param stream_id [String] the stream identifier
  # @param event [Object] any Marshal-serialisable event object
  # @return [Integer] the new stream size (version)
  def append(stream_id, event)
    @store.transaction do
      @store[:streams][stream_id] ||= []
      @store[:streams][stream_id] << event
      size = @store[:streams][stream_id].size
      size
    end
  end

  # Read all events for a stream. Wrapped in a read-only PStore transaction.
  #
  # @param stream_id [String] the stream identifier
  # @return [Array<Object>] the events in append order (empty if the stream is unknown)
  def read(stream_id)
    @store.transaction(true) do
      @store[:streams][stream_id] || []
    end
  end

  # List every known stream id.
  #
  # @return [Array<String>] the stream identifiers in insertion order
  def all_streams
    @store.transaction(true) do
      @store[:streams].keys
    end
  end
end
