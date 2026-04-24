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

booking_stream = STORE.read(booking_id)

app = BookingApp.new(booking_id, STORE)

booking = Booking.build
booking = booking_stream.reduce(booking) do |bk, event|
  app.evolve(bk, event)
end

# booking = booking_stream.reduce(booking, &method(:evolve))

puts
puts "+++ Booking Details +++"
puts "Booking: '#{booking.booking_id}'"
booking.seats.values.each do |s|
  puts "* Seat #{s.id} +£#{s.price}"
end
puts "Total: £#{booking.total}"
