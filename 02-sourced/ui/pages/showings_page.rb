# frozen_string_literal: true

module Pages
  class ShowingsPage < Pages::Page
    path '/'

    def self.load(_params, _app)
      new(movies: Catalog.movies)
    end

    def initialize(movies:)
      @movies = movies
      super()
    end

    private

    def title = "What's On"

    def container
      div(class: 'showings-page') do
        h1 { title }
        @movies.each do |movie|
          render Components::MovieCard.new(movie: movie)
        end
      end
    end
  end
end
