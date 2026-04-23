# frozen_string_literal: true

require_relative './domain'

booking_stream = []

booking_id = 'booking-1'
showing_id = 'mission-impossible-2-room2-2026-05-10T10:00'

booking = handle_command(booking_stream, StartBooking.new(booking_id:, showing_id:))
booking = handle_command(booking_stream, SelectSeat.new(booking_id:, seat_id: 'F4', price: 10))
booking = handle_command(booking_stream, SelectSeat.new(booking_id:, seat_id: 'F5', price: 11))
booking = handle_command(booking_stream, SelectSeat.new(booking_id:, seat_id: 'F6', price: 13))
booking = handle_command(booking_stream, PlaceBooking.new(booking_id:))

puts
puts "+++ Booking Details +++"
puts "Booking: '#{booking.booking_id}'"
booking.seats.values.each do |s|
  puts "* Seat #{s.id} +£#{s.price}"
end
puts "Total: £#{booking.total}"
