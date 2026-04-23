# frozen_string_literal: true

StartBooking = Data.define(:booking_id, :showing_id)
BookingStarted = Data.define(:booking_id, :showing_id, :timestamp)

BookSeat = Data.define(:booking_id, :seat_id, :price)
SeatBooked = Data.define(:booking_id, :seat_id, :price, :timestamp)

PlaceBooking = Data.define(:booking_id)
BookingPlaced = Data.define(:booking_id, :timestamp)

class Booking < Struct.new(:status, :booking_id, :showing_id, :seats, keyword_init: true)
  Seat = Struct.new(:id, :price)

  def self.build
    new(status: :open, booking_id: nil, showing_id: nil, seats: {})
  end

  def add_seat(seat_id, price)
    self.seats[seat_id] = Seat.new(seat_id, price)
  end

  def total = seats.values.sum(&:price)
end

def evolve(booking, event)
  case event
  when BookingStarted
    booking.status = :started
    booking.booking_id = event.booking_id
    booking.showing_id = event.showing_id
  when SeatBooked
    booking.add_seat(event.seat_id, event.price)
  when BookingPlaced
    booking.status = :placed
  end

  booking
end

# (booking, command) => event
def decide(booking, command)
  timestamp = Time.now

  case command
  when StartBooking
    raise 'Booking already started' if booking.status == :started
    raise 'Booking already placed' if booking.status == :placed

    BookingStarted.new(timestamp:, **command.to_h)

  when BookSeat
    raise 'Seat already booked' if booking.seats.key?(command.seat_id)

    SeatBooked.new(timestamp:, **command.to_h)

  when PlaceBooking
    raise 'Booking already placed' if booking.status == :placed
    raise 'No seats booked!' if booking.seats.size == 0

    BookingPlaced.new(timestamp:, **command.to_h)
  end
end

def handle_command(booking_stream, command)
  booking = booking_stream.reduce(Booking.build, &method(:evolve))
  new_event = decide(booking, command)
  booking_stream << new_event if new_event
  evolve(booking, new_event)
end

