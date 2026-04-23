# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative '../lib/fs_store'

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

TMP = Dir.mktmpdir('fs_store_test')
at_exit { FileUtils.remove_entry(TMP) }

def fresh_path
  File.join(TMP, "store-#{rand(1 << 32).to_s(16)}.pstore")
end

puts 'FSStore'

puts 'read returns an empty array for an unknown stream'
store = FSStore.new(fresh_path)
assert_eq store.read('missing'), [], 'empty stream reads as []'

puts 'append returns the new stream size'
store = FSStore.new(fresh_path)
assert_eq store.append('s1', :e1), 1, 'first append returns 1'
assert_eq store.append('s1', :e2), 2, 'second append returns 2'
assert_eq store.append('s1', :e3), 3, 'third append returns 3'

puts 'read returns events in append order'
store = FSStore.new(fresh_path)
store.append('s1', :e1)
store.append('s1', :e2)
store.append('s1', :e3)
assert_eq store.read('s1'), %i[e1 e2 e3], 'events preserved in order'

puts 'streams are isolated from each other'
store = FSStore.new(fresh_path)
store.append('s1', :a)
store.append('s2', :b)
store.append('s1', :c)
assert_eq store.read('s1'), %i[a c], 's1 only contains its own events'
assert_eq store.read('s2'), [:b], 's2 only contains its own events'
assert_eq store.append('s2', :d), 2, 's2 size is independent of s1'

puts 'events can be any object'
store = FSStore.new(fresh_path)
event = { type: 'BookingStarted', booking_id: 42 }
store.append('bookings/42', event)
assert_eq store.read('bookings/42'), [event], 'hash event round-trips'

puts 'events persist across instances on the same path'
path = fresh_path
writer = FSStore.new(path)
writer.append('s1', :e1)
writer.append('s1', :e2)
reader = FSStore.new(path)
assert_eq reader.read('s1'), %i[e1 e2], 'events reloaded from disk'
assert_eq reader.append('s1', :e3), 3, 'size continues from persisted state'

puts 'a new instance on a fresh path is empty'
assert_eq FSStore.new(fresh_path).read('s1'), [], 'no cross-contamination between paths'

puts
puts 'All tests passed.'
