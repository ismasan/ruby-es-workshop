# frozen_string_literal: true

require_relative '../lib/mem_store'

BookingStarted = Data.define(:booking_id, :showing_id, :timestamp)
SeatBooked = Data.define(:booking_id, :seat_id, :timestamp)
BookingPlaced = Data.define(:booking_id, :timestamp)
