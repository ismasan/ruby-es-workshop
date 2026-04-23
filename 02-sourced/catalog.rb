# frozen_string_literal: true

require 'date'

# Hard-coded movies + showings + one screen template.
# No event sourcing here — the event-sourced flow starts at seat selection.
module Catalog
  SCREEN = {
    id: 'screen1',
    name: 'Screen 1',
    rows: [
      { label: 'A', seats: 10, seat_price: 800,  aisle_after: 4 },
      { label: 'B', seats: 10, seat_price: 1000, aisle_after: 4 },
      { label: 'C', seats: 10, seat_price: 1200, aisle_after: 4 },
      { label: 'D', seats: 10, seat_price: 1400, aisle_after: 4 },
      { label: 'E', seats: 10, seat_price: 1400, aisle_after: 4 },
      { label: 'F', seats: 10, seat_price: 1600, aisle_after: 4 },
      { label: 'G', seats: 10, seat_price: 1600, aisle_after: 4 },
      { label: 'H', seats: 10, seat_price: 1200, aisle_after: 4 }
    ]
  }.freeze

  Movie = Struct.new(:movie_id, :title, :description, :duration_minutes, :poster_url, :showings, keyword_init: true)
  Showing = Struct.new(:showing_id, :movie_id, :time, :screen_id, keyword_init: true)

  TODAY = Date.today

  def self.time_today(hour, min = 0)
    Time.new(TODAY.year, TODAY.month, TODAY.day, hour, min)
  end

  MOVIES = [
    Movie.new(
      movie_id: 'dune',
      title: 'Dune: Part Two',
      description: 'Paul Atreides unites with the Fremen while seeking revenge against the conspirators who destroyed his family.',
      duration_minutes: 166,
      poster_url: 'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
      showings: [
        Showing.new(showing_id: 'dune-1400', movie_id: 'dune', time: time_today(14, 0), screen_id: 'screen1'),
        Showing.new(showing_id: 'dune-1730', movie_id: 'dune', time: time_today(17, 30), screen_id: 'screen1'),
        Showing.new(showing_id: 'dune-2100', movie_id: 'dune', time: time_today(21, 0), screen_id: 'screen1')
      ]
    ),
    Movie.new(
      movie_id: 'oppenheimer',
      title: 'Oppenheimer',
      description: 'The story of J. Robert Oppenheimer and his role in the development of the atomic bomb.',
      duration_minutes: 180,
      poster_url: 'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
      showings: [
        Showing.new(showing_id: 'opp-1500', movie_id: 'oppenheimer', time: time_today(15, 0), screen_id: 'screen1'),
        Showing.new(showing_id: 'opp-1930', movie_id: 'oppenheimer', time: time_today(19, 30), screen_id: 'screen1')
      ]
    ),
    Movie.new(
      movie_id: 'poor-things',
      title: 'Poor Things',
      description: 'The incredible tale about the fantastical evolution of Bella Baxter, a young woman brought back to life.',
      duration_minutes: 141,
      poster_url: 'https://image.tmdb.org/t/p/w500/kCGlIMHnOm8JPXq3rXM6c5wMxcT.jpg',
      showings: [
        Showing.new(showing_id: 'poor-1600', movie_id: 'poor-things', time: time_today(16, 0), screen_id: 'screen1'),
        Showing.new(showing_id: 'poor-2015', movie_id: 'poor-things', time: time_today(20, 15), screen_id: 'screen1')
      ]
    )
  ].freeze

  SHOWINGS_BY_ID = MOVIES.flat_map(&:showings).each_with_object({}) { |s, h| h[s.showing_id] = s }.freeze
  MOVIES_BY_ID = MOVIES.each_with_object({}) { |m, h| h[m.movie_id] = m }.freeze

  def self.movies = MOVIES
  def self.find_movie(movie_id) = MOVIES_BY_ID[movie_id]
  def self.find_showing(showing_id) = SHOWINGS_BY_ID[showing_id]
  def self.screen_template(_screen_id) = SCREEN
end
