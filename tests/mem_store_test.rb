# frozen_string_literal: true

require_relative '../lib/mem_store'

def assert(condition, message)
  if condition
    puts "  ok  - #{message}"
  else
    puts "  FAIL - #{message}"
    exit 1
  end
end

def assert_eq(actual, expected, message)
  assert(actual == expected, "#{message} (expected #{expected.inspect}, got #{actual.inspect})")
end

puts 'MemStore'

puts 'read returns an empty array for an unknown stream'
store = MemStore.new
assert_eq store.read('missing'), [], 'empty stream reads as []'

puts 'append returns the new stream size'
store = MemStore.new
assert_eq store.append('s1', :e1), 1, 'first append returns 1'
assert_eq store.append('s1', :e2), 2, 'second append returns 2'
assert_eq store.append('s1', :e3), 3, 'third append returns 3'

puts 'read returns events in append order'
store = MemStore.new
store.append('s1', :e1)
store.append('s1', :e2)
store.append('s1', :e3)
assert_eq store.read('s1'), %i[e1 e2 e3], 'events preserved in order'

puts 'streams are isolated from each other'
store = MemStore.new
store.append('s1', :a)
store.append('s2', :b)
store.append('s1', :c)
assert_eq store.read('s1'), %i[a c], 's1 only contains its own events'
assert_eq store.read('s2'), [:b], 's2 only contains its own events'
assert_eq store.append('s2', :d), 2, 's2 size is independent of s1'

puts 'events can be any object'
store = MemStore.new
event = { type: 'BookingStarted', booking_id: 42 }
store.append('bookings/42', event)
assert_eq store.read('bookings/42'), [event], 'hash event round-trips'

puts 'reaction block fires on append with stream_id and event'
store = MemStore.new
seen = []
store.reaction { |sid, evt| seen << [sid, evt] }
store.append('s1', :e1)
store.append('s2', :e2)
assert_eq seen, [['s1', :e1], ['s2', :e2]], 'reaction received every append in order'

puts 'reaction accepts a positional callable'
store = MemStore.new
seen = []
callable = ->(sid, evt) { seen << [sid, evt] }
store.reaction(callable)
store.append('s1', :e1)
assert_eq seen, [['s1', :e1]], 'lambda reaction fired'

puts 'reaction returns self for chaining'
store = MemStore.new
assert_eq store.reaction { |_, _| }, store, 'reaction returns self'

puts 'multiple reactions all fire, in registration order'
store = MemStore.new
calls = []
store.reaction { |_sid, evt| calls << [:first, evt] }
store.reaction { |_sid, evt| calls << [:second, evt] }
store.append('s1', :e1)
assert_eq calls, [[:first, :e1], [:second, :e1]], 'both reactions fired in order'

puts 'reactions fire after the event is written to the log'
store = MemStore.new
snapshots = []
store.reaction { |sid, _evt| snapshots << store.read(sid).dup }
store.append('s1', :e1)
store.append('s1', :e2)
assert_eq snapshots, [[:e1], %i[e1 e2]], 'reaction sees the just-appended event in the log'

puts 'reactions do not fire for appends that happened before registration'
store = MemStore.new
store.append('s1', :before)
seen = []
store.reaction { |sid, evt| seen << [sid, evt] }
store.append('s1', :after)
assert_eq seen, [['s1', :after]], 'only post-registration appends trigger the reaction'

puts 'a raising reaction propagates but the event is already appended'
store = MemStore.new
store.reaction { |_sid, _evt| raise 'boom' }
raised = begin
  store.append('s1', :e1)
  false
rescue RuntimeError => e
  e.message == 'boom'
end
assert raised, 'append re-raised the reaction error'
assert_eq store.read('s1'), [:e1], 'event remained in the log despite reaction error'

puts
puts 'All tests passed.'
