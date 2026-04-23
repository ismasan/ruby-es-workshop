# frozen_string_literal: true

module Components
  class FilmBar < Sidereal::Components::BaseComponent
    def initialize(movie:, showing:)
      @movie = movie
      @showing = showing
    end

    def view_template
      header(class: 'film-bar') do
        div(class: 'film-bar__poster') do
          if @movie.poster_url
            img(src: @movie.poster_url, alt: @movie.title, class: 'film-bar__poster-img')
          else
            plain 'poster'
          end
        end
        div(class: 'film-bar__info') do
          span(class: 'film-bar__title') { @movie.title }
          div(class: 'film-bar__details') do
            span(class: 'film-bar__detail') do
              span(class: 'film-bar__detail-label') { 'Cinema' }
              plain ' Screenside Luxe, Leicester Sq.'
            end
            span(class: 'film-bar__detail') do
              span(class: 'film-bar__detail-label') { 'Screen' }
              plain " #{@showing.screen_id}"
            end
            span(class: 'film-bar__detail') do
              span(class: 'film-bar__detail-label') { 'Time' }
              plain " #{@showing.time.strftime('%a %-d %b, %H:%M')}"
            end
          end
        end
      end
    end
  end
end
