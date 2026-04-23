# frozen_string_literal: true

require_relative './domain'

booking_stream = []

booking_id = 'booking-1'
showing_id = 'mission-impossible-2-room2-2026-05-10T10:00'

booking_stream << BookingStarted.new(booking_id:, showing_id:, timestamp: Time.now)
booking_stream << SeatBooked.new(booking_id:, seat_id: 'F4', price: 10, timestamp: Time.now)
booking_stream << SeatBooked.new(booking_id:, seat_id: 'F5', price: 15, timestamp: Time.now)
booking_stream << BookingPlaced.new(booking_id:, timestamp: Time.now)

booking = Booking.build
booking = booking_stream.reduce(booking) do |bk, event|
  evolve(bk, event)
end
# booking = booking_stream.reduce(booking, &method(:evolve))
puts
puts "+++ Booking Details +++"
puts "Booking: '#{booking.booking_id}'"
booking.seats.values.each do |s|
  puts "* Seat #{s.id} +£#{s.price}"
end
puts "Total: £#{booking.total}"
