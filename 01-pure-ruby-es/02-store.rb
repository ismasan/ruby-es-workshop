# frozen_string_literal: true

require_relative './domain'
require_relative '../lib/mem_store'

STORE = MemStore.new

booking_id = 'booking-1'
showing_id = 'mission-impossible-2-room2-2026-05-10T10:00'

STORE.append booking_id, BookingStarted.new(booking_id:, showing_id:, timestamp: Time.now)
STORE.append booking_id, SeatSelected.new(booking_id:, seat_id: 'F4', price: 10, timestamp: Time.now)
STORE.append booking_id, SeatSelected.new(booking_id:, seat_id: 'F5', price: 15, timestamp: Time.now)
STORE.append booking_id, BookingPlaced.new(booking_id:, timestamp: Time.now)

STORE.read(booking_id).each do |evt|
  p evt
end
