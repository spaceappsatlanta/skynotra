require 'bundler'
require 'json'

Bundler.require if defined?(Bundler)

module Skynotra
  class Application < Sinatra::Application
    get '/' do
      'Hello world'
    end

    get '/observations/:target' do
      target_request = SkyMorph::TargetRequest.new(params[:target])
      target_response = target_request.fetch
      observations = SkyMorph::ObservationTableParser.parse(target_response)
      deliver(observations)
    end

    private
    def deliver(object)
      content_type :json
      JSON.dump object
    end
  end
end
