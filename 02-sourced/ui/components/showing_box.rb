# frozen_string_literal: true

module Components
  class ShowingBox < Sidereal::Components::BaseComponent
    def initialize(showing:)
      @showing = showing
    end

    def view_template
      a(href: "/bookings/#{@showing.showing_id}", class: 'showing-box') do
        div(class: 'showing-box__times') do
          span(class: 'showing-box__start-time') { @showing.time.strftime('%H:%M') }
        end
        div(class: 'showing-box__meta') do
          span(class: 'showing-box__screen') { @showing.screen_id }
        end
      end
    end
  end
end
