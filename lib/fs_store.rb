# frozen_string_literal: true

require 'pstore'

class FSStore
  def initialize(path = 'events.pstore')
    @store = PStore.new(path)
  end

  def append(stream_id, event)
    @store.transaction do
      @store[stream_id] ||= []
      @store[stream_id] << event
      @store[stream_id].size
    end
  end

  def read(stream_id)
    @store.transaction(true) do
      @store[stream_id] || []
    end
  end
end
