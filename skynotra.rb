require 'bundler'
require 'json'
require 'net/http'
require 'uri'

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

    get '/images/:key.json' do
      image_url = get_image_url(params[:key])
      deliver({image_url: image_url})
    end

    get '/images/:key.gif' do
      content_type :gif
      image_url = URI.parse(get_image_url(params[:key]))
      Net::HTTP.get_response(image_url).body
    end

    private
    def deliver(object)
      content_type :json
      JSON.dump object
    end

    def get_image_url(key)
      image_request = SkyMorph::ImageRequest.new(params[:key])
      image_response = image_request.fetch
      image_parser = SkyMorph::ImageParser.new
      image_parser.parse_html(image_response)
    end
  end
end
