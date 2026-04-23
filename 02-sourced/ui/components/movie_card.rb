# frozen_string_literal: true

module Components
  class MovieCard < Sidereal::Components::BaseComponent
    def initialize(movie:)
      @movie = movie
    end

    def view_template
      article(class: 'movie-card') do
        div(class: 'movie-card__poster') do
          if @movie.poster_url
            img(src: @movie.poster_url, alt: @movie.title, class: 'movie-card__poster-img')
          else
            plain 'poster'
          end
        end
        div(class: 'movie-card__body') do
          div(class: 'movie-card__info') do
            h2(class: 'movie-card__title') { @movie.title }
            p(class: 'movie-card__description') { @movie.description }
            small(class: 'movie-card__duration') { "#{@movie.duration_minutes} mins" }
          end
          div(class: 'showings') do
            @movie.showings.each do |showing|
              render ShowingBox.new(showing: showing)
            end
          end
        end
      end
    end
  end
end
