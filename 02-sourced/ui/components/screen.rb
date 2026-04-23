# frozen_string_literal: true

module Components
  class Screen < Sidereal::Components::BaseComponent
    def initialize(showing:, screen:, booking_id:)
      @showing = showing
      @screen = screen
      @booking_id = booking_id
    end

    def view_template
      div(class: 'screen-layout') do
        h1 { @screen.name }
        div(class: 'screen') { 'screen' }
        div(class: 'seating') do
          @screen.rows.each do |row|
            whitespace
            comment { "Row #{row.label}" }
            render_row(row)
          end
        end
        whitespace
        comment { 'Legend' }
        legend
      end
    end

    private

    def render_row(row)
      div(class: 'row', data_row: row.label) do
        whitespace
        span(class: 'row-label') { row.label }
        div(class: 'seats') do
          row.seats.each_with_index do |seat, index|
            render_seat(seat)
            div(class: 'aisle') if row.aisle_after && index == row.aisle_after - 1
          end
        end
      end
    end

    def render_seat(seat)
      if seat.available?
        select_form(seat)
      elsif seat.selected?
        deselect_form(seat)
      else
        div(class: 'seat seat--unavailable', title: seat.id)
      end
    end

    def select_form(seat)
      command SeatSelection::Select, class: 'seat seat--available' do |cmd|
        cmd.payload_fields(showing_id: @showing.showing_id, seat_id: seat.id, booking_id: @booking_id)
        button(type: 'submit', title: seat.id) { seat.price_display }
      end
    end

    def deselect_form(seat)
      command SeatSelection::Deselect, class: 'seat seat--selected' do |cmd|
        cmd.payload_fields(showing_id: @showing.showing_id, seat_id: seat.id, booking_id: @booking_id)
        button(type: 'submit', title: seat.id) { seat.price_display }
      end
    end

    def legend
      div(class: 'legend') do
        div(class: 'legend-item') do
          div(class: 'legend-swatch legend-swatch--available')
          plain ' Available'
        end
        div(class: 'legend-item') do
          div(class: 'legend-swatch legend-swatch--unavailable')
          plain ' Unavailable'
        end
        div(class: 'legend-item') do
          div(class: 'legend-swatch legend-swatch--selected')
          plain ' Selected'
        end
      end
    end
  end
end
