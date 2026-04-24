# frozen_string_literal: true

require_relative './domain'
require_relative '../lib/mem_store'

STORE = MemStore.new

booking_id = 'booking-1'
showing_id = 'mission-impossible-2-room2-2026-05-10T10:00'

app = BookingApp.new(booking_id, STORE)

booking = app.handle(StartBooking.new(booking_id:, showing_id:))
booking = app.handle(SelectSeat.new(booking_id:, seat_id: 'F4', price: 10))
booking = app.handle(SelectSeat.new(booking_id:, seat_id: 'F5', price: 11))
booking = app.handle(SelectSeat.new(booking_id:, seat_id: 'F6', price: 13))
booking = app.handle(PlaceBooking.new(booking_id:))

puts
puts "+++ Booking Details +++"
puts "Booking: '#{booking.booking_id}'"
booking.seats.values.each do |s|
  puts "* Seat #{s.id} +£#{s.price}"
end
puts "Total: £#{booking.total}"
