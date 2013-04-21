require 'bundler'

Bundler.require if defined?(Bundler)

module Skynotra
  class Application < Sinatra::Application
    get '/' do
      'Hello world'
    end
  end
end
