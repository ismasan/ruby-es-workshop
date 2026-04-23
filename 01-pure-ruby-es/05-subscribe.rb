# frozen_string_literal: true

require_relative './domain'
require_relative '../lib/fs_store'

STORE = FSStore.new

Signal.trap('INT') do
  STORE.subscriptions.stop
  Signal.trap('INT', 'DEFAULT')
end

emails = STORE.subscriptions.subscribe 'emails' do |stream_id, event|
  p [:emails, stream_id, event]
end

caches = STORE.subscriptions.subscribe 'caches' do |stream_id, event|
  p [:caches, stream_id, event]
end

[emails, caches].each(&:join)
p :done
