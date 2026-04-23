# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'stringio'
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

def fresh_dir
  File.join(TMP, "store-#{rand(1 << 32).to_s(16)}")
end

def wait_until(timeout: 2.0, step: 0.02)
  deadline = Time.now + timeout
  until yield
    return false if Time.now > deadline

    sleep step
  end
  true
end

def silence_stderr
  original = $stderr
  $stderr = StringIO.new
  yield
ensure
  $stderr = original
end

puts 'FSStore'

puts 'read returns an empty array for an unknown stream'
store = FSStore.new(fresh_dir)
assert_eq store.read('missing'), [], 'empty stream reads as []'

puts 'append returns the new stream size'
store = FSStore.new(fresh_dir)
assert_eq store.append('s1', :e1), 1, 'first append returns 1'
assert_eq store.append('s1', :e2), 2, 'second append returns 2'
assert_eq store.append('s1', :e3), 3, 'third append returns 3'

puts 'read returns events in append order'
store = FSStore.new(fresh_dir)
store.append('s1', :e1)
store.append('s1', :e2)
store.append('s1', :e3)
assert_eq store.read('s1'), %i[e1 e2 e3], 'events preserved in order'

puts 'streams are isolated from each other'
store = FSStore.new(fresh_dir)
store.append('s1', :a)
store.append('s2', :b)
store.append('s1', :c)
assert_eq store.read('s1'), %i[a c], 's1 only contains its own events'
assert_eq store.read('s2'), [:b], 's2 only contains its own events'
assert_eq store.append('s2', :d), 2, 's2 size is independent of s1'

puts 'events can be any object'
store = FSStore.new(fresh_dir)
event = { type: 'BookingStarted', booking_id: 42 }
store.append('bookings/42', event)
assert_eq store.read('bookings/42'), [event], 'hash event round-trips'

puts 'events persist across instances on the same path'
path = fresh_dir
writer = FSStore.new(path)
writer.append('s1', :e1)
writer.append('s1', :e2)
reader = FSStore.new(path)
assert_eq reader.read('s1'), %i[e1 e2], 'events reloaded from disk'
assert_eq reader.append('s1', :e3), 3, 'size continues from persisted state'

puts 'a new instance on a fresh path is empty'
assert_eq FSStore.new(fresh_dir).read('s1'), [], 'no cross-contamination between paths'

puts 'subscribe delivers events appended before and after subscribing'
store = FSStore.new(fresh_dir)
store.append('s1', :before_a)
store.append('s1', :before_b)
received = []
thread = store.subscribe('sub-1') { |sid, event| received << [sid, event] }
wait_until { received.size >= 2 }
store.append('s1', :after_a)
store.append('s2', :after_b)
ok = wait_until { received.size >= 4 }
thread.kill
assert ok, 'subscriber received all 4 events within timeout'
assert_eq received.first(2), [['s1', :before_a], ['s1', :before_b]], 'pre-subscribe events delivered'
assert received.include?(['s1', :after_a]), 's1 post-subscribe event delivered'
assert received.include?(['s2', :after_b]), 's2 post-subscribe event delivered'

puts 'subscribe advances offset only to last successful event on raise'
dir = fresh_dir
store = FSStore.new(dir)
store.append('s1', :a)
store.append('s1', :b)
store.append('s1', :bad)
store.append('s1', :c)
store.append('s2', :x)
received = []
attempts = Hash.new(0)
thread = silence_stderr do
  t = store.subscribe('sub-2') do |sid, event|
    attempts[[sid, event]] += 1
    raise 'boom' if event == :bad

    received << [sid, event]
  end
  # Let the loop run long enough for the bad event to be retried several times.
  wait_until { attempts[['s1', :bad]] >= 3 && received.include?(['s2', :x]) }
  t
end
thread.kill
assert_eq received, [['s1', :a], ['s1', :b], ['s2', :x]], 'successful events delivered in order, bad event not included'
assert attempts[['s1', :bad]] >= 3, "bad event was retried (#{attempts[['s1', :bad]]} attempts)"
assert_eq attempts[['s1', :c]], 0, 'events after bad on same stream are not delivered while bad keeps failing'

puts 'subscriber offsets persist across instances'
resume = FSStore.new(dir)
resumed = []
thread = silence_stderr do
  t = resume.subscribe('sub-2') do |sid, event|
    raise 'boom' if event == :bad

    resumed << [sid, event]
  end
  # Give the loop a moment — it should find nothing new for s2 (already processed)
  # but still retry :bad on s1.
  sleep 0.2
  t
end
thread.kill
assert_eq resumed, [], 'previously-processed events are not re-delivered after resume'

puts
puts 'All tests passed.'
