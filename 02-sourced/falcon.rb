# falcon.rb
#!/usr/bin/env falcon-host

require 'sourced'
require 'sourced/falcon'

service "seats" do
  include Sourced::Falcon::Environment
  include Falcon::Environment::Rackup

  url "http://[::]:9292"                 # Server bind URL (default: "http://[::]:9292")
  count 1
  # timeout 30                             # Connection timeout in seconds (default: nil)
  verbose false                          # Enable verbose logging (default: false)
  cache true                             # Enable HTTP response caching (default: false)
end
