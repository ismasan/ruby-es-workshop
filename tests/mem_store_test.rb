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

puts
puts 'All tests passed.'
