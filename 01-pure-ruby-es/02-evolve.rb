# frozen_string_literal: true

require_relative './domain'

class Cart < Struct.new(:status, :booking_id, :showing_id, :seats, keyword_init: true)
  Seat = Struct.new(:id, :price)

  def self.build
    new(status: :open, booking_id: nil, showing_id: nil, seats: {})
  end

  def add_seat(seat_id, price)
    self.seats[seat_id] = Seat.new(seat_id, price)
  end

  def total = seats.values.sum(&:price)
end

def evolve(cart, event)
  case event
  when BookingStarted
    cart.status = :started
    cart.booking_id = event.booking_id
    cart.showing_id = event.showing_id
  when SeatBooked
    cart.add_seat(event.seat_id, event.price)
  when BookingPlaced
    cart.status = :placed
  end

  cart
end

booking_stream = []

booking_id = 'booking-1'
showing_id = 'mission-impossible-2-room2-2026-05-10T10:00'

booking_stream << BookingStarted.new(booking_id:, showing_id:, timestamp: Time.now)
booking_stream << SeatBooked.new(booking_id:, seat_id: 'F4', price: 10, timestamp: Time.now)
booking_stream << SeatBooked.new(booking_id:, seat_id: 'F5', price: 15, timestamp: Time.now)
booking_stream << BookingPlaced.new(booking_id:, timestamp: Time.now)

cart = Cart.build
cart = booking_stream.reduce(cart) do |crt, event|
  evolve(crt, event)
end
# cart = booking_stream.reduce(cart, &method(:evolve))
puts
puts "+++ Cart Details +++"
puts "Booking: '#{cart.booking_id}'"
cart.seats.values.each do |s|
  puts "* Seat #{s.id} +£#{s.price}"
end
puts "Total: £#{cart.total}"
