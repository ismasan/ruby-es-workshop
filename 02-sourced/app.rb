# frozen_string_literal: true

require 'securerandom'

class App < Sidereal::App
  session secret: 'x' * 64 #ENV.fetch('SESSION_SECRET')
  layout Layouts::Layout

  page Pages::ShowingsPage
  page Pages::BookingPage

  # handle blocks handle commands in the HTTP request phase
  # Here we can run any sync validations, and decorate the command with metadata
  # before dispatching it to the async runtime with dispatch(cmd)
  handle SeatSelection::Select, SeatSelection::Deselect do |cmd|
    cmd = cmd.with_metadata(producer: 'UI', session_id: session_id)
    cmd = cmd.with_payload(booking_id:) if cmd.class.payload_attribute_names.include?(:booking_id)
    dispatch cmd
    status 200
  end

  def session_id
    session[:id] ||= SecureRandom.uuid
  end

  def booking_id
    session[:booking_id] ||= SecureRandom.uuid
  end
end
