# frozen_string_literal: true

require 'nokogiri'
require 'erb'
require 'fileutils'
require_relative './domain'
require_relative '../lib/fs_store'

STORE = FSStore.new

Signal.trap('INT') do
  STORE.subscriptions.stop
  Signal.trap('INT', 'DEFAULT')
end

# State-stored projector: the rendered HTML file is the only place the
# projection state lives. On each event we re-read the previous page, extract
# booking state with Nokogiri, apply the event to our own view model, and
# rewrite the whole page.
#
# Recovery note: if `projections/index.html` is deleted while the store still
# has subscriber offsets, prior events won't be replayed and history is lost.
# Workshop recovery: wipe both `store/` and `projections/` and restart.
class HTMLProjector
  BookingView = Struct.new(:booking_id, :showing_id, :status, :seats, keyword_init: true) do
    def self.empty(booking_id)
      new(booking_id: booking_id, showing_id: nil, status: :open, seats: {})
    end

    def total
      seats.values.sum { |s| s[:price] }
    end
  end

  TEMPLATE = ERB.new(<<~HTML)
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta http-equiv="refresh" content="1">
        <title>Bookings</title>
        <style>
          body { font-family: system-ui, sans-serif; max-width: 48rem; margin: 2rem auto; padding: 0 1rem; color: #222; }
          h1 { font-size: 1.4rem; margin-bottom: 1.5rem; }
          .booking { border: 1px solid #ddd; padding: 1rem 1.25rem; margin-bottom: 1rem; border-radius: .5rem; background: #fafafa; }
          .booking h2 { font-size: 1.1rem; margin: 0 0 .75rem; display: flex; align-items: baseline; justify-content: space-between; gap: 1rem; }
          .status { font-size: .7rem; letter-spacing: .1em; text-transform: uppercase; color: #fff; background: #888; padding: .2rem .5rem; border-radius: 1rem; }
          .status[data-v="started"] { background: #2b7cff; }
          .status[data-v="placed"]  { background: #1f9d55; }
          .seats { list-style: none; padding: 0; margin: 0 0 .75rem; display: flex; flex-wrap: wrap; gap: .5rem; }
          .seats li { background: #fff; border: 1px solid #e2e2e2; padding: .25rem .6rem; border-radius: .25rem; font-size: .9rem; }
          .total { font-weight: 600; margin: 0; }
          .showing { color: #666; font-size: .85rem; margin: -.5rem 0 .75rem; }
        </style>
      </head>
      <body>
        <h1>Bookings</h1>
        <main id="bookings">
          <% bookings.each do |b| %>
            <article class="booking"
                     data-booking-id="<%= b.booking_id %>"
                     data-showing-id="<%= b.showing_id %>"
                     data-status="<%= b.status %>">
              <h2>
                <span>Booking <%= b.booking_id %></span>
                <span class="status" data-v="<%= b.status %>"><%= b.status %></span>
              </h2>
              <p class="showing">Showing: <%= b.showing_id %></p>
              <ul class="seats">
                <% b.seats.each_value do |s| %>
                  <li data-seat-id="<%= s[:id] %>" data-price="<%= s[:price] %>">
                    <%= s[:id] %> — £<%= s[:price] %>
                  </li>
                <% end %>
              </ul>
              <p class="total">Total: £<%= b.total %></p>
            </article>
          <% end %>
        </main>
      </body>
    </html>
  HTML

  def initialize(dir = './projections')
    @dir = dir
    FileUtils.mkdir_p(@dir)
    @path = File.join(@dir, 'index.html')
  end

  def call(_stream_id, event)
    booking_id = event.booking_id if event.respond_to?(:booking_id)
    return unless booking_id

    bookings = load_bookings
    view = bookings[booking_id] ||= BookingView.empty(booking_id)
    return unless apply(view, event)

    write(bookings.values)
    p ['projected event', event]
  end

  private

  def apply(view, event)
    case event
    when BookingStarted
      view.booking_id = event.booking_id
      view.showing_id = event.showing_id
      view.status = :started
    when SeatSelected
      view.seats[event.seat_id] = { id: event.seat_id, price: event.price }
    when BookingPlaced
      view.status = :placed
    else
      return nil
    end
    true
  end

  def load_bookings
    return {} unless File.exist?(@path)

    doc = Nokogiri::HTML(File.read(@path))
    doc.css('#bookings article.booking').each_with_object({}) do |node, acc|
      seats = node.css('ul.seats li').each_with_object({}) do |li, h|
        id = li['data-seat-id']
        h[id] = { id: id, price: li['data-price'].to_i }
      end
      acc[node['data-booking-id']] = BookingView.new(
        booking_id: node['data-booking-id'],
        showing_id: node['data-showing-id'],
        status:     node['data-status'].to_sym,
        seats:      seats
      )
    end
  end

  def write(bookings)
    html = TEMPLATE.result_with_hash(bookings: bookings)
    tmp = "#{@path}.tmp"
    File.write(tmp, html)
    File.rename(tmp, @path)
  end
end

html_list = STORE.subscriptions.subscribe 'HTML list', HTMLProjector.new

[html_list].each(&:join)
p :done
