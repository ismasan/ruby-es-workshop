# frozen_string_literal: true

BookingStarted = Data.define(:booking_id, :showing_id, :timestamp)
SeatBooked = Data.define(:booking_id, :seat_id, :price, :timestamp)
BookingPlaced = Data.define(:booking_id, :timestamp)
