# frozen_string_literal: true

module Components
  class Cart < Sidereal::Components::BaseComponent
    def initialize(screen:, version: nil)
      @screen = screen
      @version = version
    end

    def view_template
      selected = @screen.selected_seats
      total = selected.sum(&:price_cents)

      aside(class: 'sidebar') do
        h2 do
          plain 'Your Booking'
          span(class: 'sidebar__version') { "v#{@version}" } if @version
        end
        p(class: 'booking-count') { "#{selected.size} seats selected" }
        ul(class: 'booking-seats') do
          selected.each do |seat|
            li(class: 'booking-seat') do
              span(class: 'booking-seat__id') { seat.id }
              span(class: 'booking-seat__price') { seat.price_display }
            end
          end
        end
        div(class: 'booking-footer') do
          hr(class: 'booking-divider')
          div(class: 'booking-total') do
            span(class: 'booking-total__label') { 'Total' }
            span(class: 'booking-total__price') { price_display(total) }
          end
        end
      end
    end

    private

    def price_display(cents)
      '$%.2f' % (cents / 100.0)
    end
  end
end
