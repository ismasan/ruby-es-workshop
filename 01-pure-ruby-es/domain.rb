# frozen_string_literal: true

StartBooking = Data.define(:booking_id, :showing_id)
BookingStarted = Data.define(:booking_id, :showing_id, :timestamp)

SelectSeat = Data.define(:booking_id, :seat_id, :price)
SeatSelected = Data.define(:booking_id, :seat_id, :price, :timestamp)

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

class BookingApp
  def initialize(stream_id, store)
    @stream_id = stream_id
    @store = store
  end

  def evolve(booking, event)
    case event
    when BookingStarted
      booking.status = :started
      booking.booking_id = event.booking_id
      booking.showing_id = event.showing_id
    when SeatSelected
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

    when SelectSeat
      raise 'Seat already booked' if booking.seats.key?(command.seat_id)

      SeatSelected.new(timestamp:, **command.to_h)

    when PlaceBooking
      raise 'Booking already placed' if booking.status == :placed
      raise 'No seats booked!' if booking.seats.size == 0

      BookingPlaced.new(timestamp:, **command.to_h)
    end
  end

  def handle(command)
    # 1. read past events for @stream_id
    booking_stream = @store.read(@stream_id)
    # 2. reduce events and evolve booking state
    booking = booking_stream.reduce(Booking.build, &method(:evolve))
    # 3. pass booking and command to decide function
    new_event = decide(booking, command)
    # 4. evolve new event to get up-to-date state
    booking = evolve(booking, new_event)

    # 5. append new event to store
    if new_event
      @store.append(@stream_id, new_event) 
    end

    booking
  end

  def start(showing_id:)
    handle StartBooking.new(booking_id: @stream_id, showing_id:)
  end

  def select_seat(seat_id:, price:)
    handle SelectSeat.new(booking_id: @stream_id, seat_id:, price:)
  end

  def place
    handle PlaceBooking.new(booking_id: @stream_id)
  end
end

