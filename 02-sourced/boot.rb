# frozen_string_literal: true

require 'zeitwerk'
require 'sequel'
require 'sqlite3'
require 'sourced'
require 'sidereal'
require 'brotli'
require 'datastar'
require 'dotenv'
Dotenv.load '.env'

UI_LOADER = Zeitwerk::Loader.new
UI_LOADER.push_dir("#{__dir__}/ui")
UI_LOADER.enable_reloading
UI_LOADER.setup

CODE_LOADER = Zeitwerk::Loader.new
CODE_LOADER.push_dir("#{__dir__}/domain")
CODE_LOADER.setup

$LOAD_PATH.unshift File.dirname(__FILE__)

require_relative 'catalog'

Sourced.configure do |config|
  unless ENV['TEST']
    db = Sequel.sqlite('./storage/data.db')
    config.store = db
  end

  config.error_strategy do |s|
    s.retry(times: 1, after: 1)
    s.on_fail do |exception, _message|
      Sourced.config.logger.error(exception.backtrace.join("\n"))
    end
  end
end

Sidereal.configure do |config|
  config.store = Sourced.store
  config.dispatcher = Sourced::Dispatcher
end

Sourced.register(SeatSelection)

Zeitwerk::Loader.eager_load_all if ENV['RACK_ENV'] == 'production'
