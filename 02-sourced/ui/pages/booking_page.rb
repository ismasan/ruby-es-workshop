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
      requested_version = params[:version]&.to_i
      view, events = Sourced.load(BookingView, showing_id: showing_id, upto: requested_version)
      screen = Screen.from_template(template, held: view.state[:held], current_booking_id: app.booking_id)

      new(
        movie: movie,
        showing: showing,
        screen: screen,
        booking_id: app.booking_id,
        version: events.messages.size,
        historic: !requested_version.nil?
      )
    end

    on SeatSelection::Updated do |evt|
      next unless evt.payload.showing_id == params[:showing_id]
      browser.patch_elements load(params)
    end

    def initialize(movie:, showing:, screen:, booking_id:, version:, historic: false)
      @movie = movie
      @showing = showing
      @screen = screen
      @booking_id = booking_id
      @version = version
      @historic = historic
      super()
    end

    # Suppress the live-update subscription when viewing a historic version,
    # so the frozen snapshot isn't overwritten by subsequent SeatSelection
    # events. (Page.subscribe returns early when page_key is absent.)
    def page_signals
      @historic ? {} : super
    end

    private

    def title = "Booking - #{@movie.title}"

    def container
      render Components::FilmBar.new(movie: @movie, showing: @showing)
      div(class: 'layout') do
        render Components::Screen.new(showing: @showing, screen: @screen, booking_id: @booking_id)
        render Components::Cart.new(screen: @screen, version: @version)
      end
    end
  end
end
