# frozen_string_literal: true

module Layouts
  class Layout < Sidereal::Components::Layout
    def view_template
      doctype
      html do
        head do
          meta(name: 'viewport', content: 'width=device-width, initial-scale=1.0')
          title { title_text }
          link(rel: 'stylesheet', href: "/css/main.css?#{Time.now.to_i}")
        end
        body do
          nav(class: 'top-nav') do
            a(href: '/', class: 'top-nav__brand') { 'Screenside' }
            ul(class: 'top-nav__links') do
              li { a(href: '/') { "What's On" } }
              li { a(href: '/sourced') { 'System' } }
            end
          end

          div(class: 'page') do
            render @page
          end
        end
      end
    end

    private def title_text
      @page.respond_to?(:title, true) ? @page.send(:title) : 'Screenside'
    end
  end
end
