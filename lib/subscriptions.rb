# frozen_string_literal: true

class Subscriptions
  Subscriber = Struct.new(:id, :streams)

  POLL_INTERVAL = 0.05

  def initialize(store)
    @store = store
    @running = true
    @store.transaction do
      @store[:subscribers] ||= {}
    end
  end

  def stop
    @running = false
  end

  # Register a subscriber that is notified of events appended to any stream.
  # Returns the background polling thread so callers can join or kill it.
  #
  # The subscriber tracks a per-stream offset (last processed version) in the
  # store, so it resumes from where it left off across process restarts.
  #
  # On the poll thread:
  #   1. Snapshot new events under a read-only transaction.
  #   2. Invoke the callback outside any transaction (so it can't freeze writes
  #      or deadlock if it calls #append).
  #   3. Persist the highest successfully processed offset per stream under a
  #      write transaction. If the callback raises, the offset advances only up
  #      to the last event that returned cleanly — the failing event is retried
  #      on the next tick.
  #
  # @param subscriber_id [String] stable identifier used to persist offsets
  # @yieldparam stream_id [String] the stream the event came from
  # @yieldparam event [Object] the event itself
  # @return [Thread] the polling thread
  def subscribe(subscriber_id, sub = nil, &work)
    sub ||= work

    @store.transaction do
      @store[:subscribers][subscriber_id] ||= Subscriber.new(subscriber_id, {})
    end

    Thread.new do
      while @running do
        begin
          poll(subscriber_id, sub)
        rescue StandardError => e
          warn "subscriber #{subscriber_id} loop error: #{e.class}: #{e.message}"
        end
        sleep POLL_INTERVAL
      end
    end
  end

  private

  def poll(subscriber_id, sub)
    snapshot = {}
    @store.transaction(true) do
      offsets = @store[:subscribers][subscriber_id].streams
      @store[:streams].each do |stream_id, stream|
        offset = offsets[stream_id] || 0
        snapshot[stream_id] = [offset, stream[offset..]] if offset < stream.size
      end
    end
    return if snapshot.empty?

    progress = {}
    snapshot.each do |stream_id, (start, events)|
      events.each_with_index do |event, i|
        begin
          sub.call(stream_id, event)
          progress[stream_id] = start + i + 1
        rescue StandardError => e
          warn "subscriber #{subscriber_id} raised on #{stream_id}[#{start + i}]: #{e.class}: #{e.message}"
          break
        end
      end
    end
    return if progress.empty?

    @store.transaction do
      offsets = @store[:subscribers][subscriber_id].streams
      progress.each { |sid, off| offsets[sid] = off }
    end
  end
end
