# frozen_string_literal: true

module Pages
  class BookingPage < Pages::Page
    path '/bookings/:showing_id'

    def self.load(params, app)
      showing_id = params[:showing_id]
      showing = Catalog.find_showing(showing_id)
      raise "Unknown showing #{showing_id}" unless showing

      movie = Catalog.find_movie(showing.movie_id)
      template = Catalog.screen_template(showing.screen_id)
      view, _ = Sourced.load(SeatsHeld, showing_id: showing_id)
      screen = Screen.from_template(template, held: view.state[:held], current_booking_id: app.booking_id)

      new(movie: movie, showing: showing, screen: screen, booking_id: app.booking_id)
    end

    on SeatSelection::Updated do |evt|
      next unless evt.payload.showing_id == params[:showing_id]
      browser.patch_elements load(params)
    end

    def initialize(movie:, showing:, screen:, booking_id:)
      @movie = movie
      @showing = showing
      @screen = screen
      @booking_id = booking_id
      super()
    end

    private

    def title = "Booking - #{@movie.title}"

    def container
      render Components::FilmBar.new(movie: @movie, showing: @showing)
      div(class: 'layout') do
        render Components::Screen.new(showing: @showing, screen: @screen, booking_id: @booking_id)
        render Components::Cart.new(screen: @screen)
      end
    end
  end
end
