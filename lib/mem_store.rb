# frozen_string_literal: true

class MemStore
  def initialize
    @log = Hash.new { |h, k| h[k] = [] }
  end

  def append(stream_id, event)
    @log[stream_id] << event

    @log[stream_id].size
  end

  def read(stream_id)
    @log[stream_id]
  end
end
