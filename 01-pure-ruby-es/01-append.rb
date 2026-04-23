# frozen_string_literal: true

require_relative './domain'

booking_stream = []

booking_id = 'booking-1'
showing_id = 'mission-impossible-2-room2-2026-05-10T10:00'

booking_stream << BookingStarted.new(booking_id:, showing_id:, timestamp: Time.now)
booking_stream << SeatSelected.new(booking_id:, seat_id: 'F4', price: 10, timestamp: Time.now)
booking_stream << SeatSelected.new(booking_id:, seat_id: 'F5', price: 15, timestamp: Time.now)
booking_stream << BookingPlaced.new(booking_id:, timestamp: Time.now)
