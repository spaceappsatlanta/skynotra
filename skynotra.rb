require 'bundler'
require 'json'
require 'net/http'
require 'redis'
require 'uri'

Bundler.require if defined?(Bundler)

before do
  $redis = Redis.new
end

def cache key, &block
  if val = $redis.get(key)
    val
  else
    val = block.call
    $redis.set key, val
    val
  end
end

module Skynotra
  class Application < Sinatra::Application
    get '/' do
      'Hello world'
    end

    get '/observations/:target' do
      content_type :json
      cache request.path do
        observations = SkyMorph::Observation.find(params[:target]).map(&:to_hash)
        JSON.dump observations
      end
    end

    get '/images/:key.json' do
      content_type :json
      cache request.path do
        image_url = get_image_url(params[:key])
        JSON.dump { image_url: image_url }
      end
    end

    get '/images/:key.gif' do
      content_type :gif
      image_url = URI.parse(get_image_url(params[:key]))
      Net::HTTP.get_response(image_url).body
    end

    private

    def get_image_url(key)
      image_request = SkyMorph::ImageRequest.new(params[:key])
      image_response = image_request.fetch
      image_parser = SkyMorph::ImageParser.new
      image_parser.parse_html(image_response)
    end
  end
end
