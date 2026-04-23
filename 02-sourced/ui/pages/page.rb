# frozen_string_literal: true

module Pages
  class Page < Sidereal::Page
    def view_template
      div(id: 'container', class: 'container') do
        container
      end
    end

    private

    def title = 'Page'

    def container
      h1 { title }
    end
  end
end
