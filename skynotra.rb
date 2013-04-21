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
    set :public_folder, 'public'

    get '/' do
      slim :index
    end

    get '/observations.json' do
      content_type :json
      cache "observations:#{params[:target]}" do
        observations = SkyMorph::Observation.find(params[:target]).map(&:to_hash)
        JSON.dump(observations)
      end
    end

    get '/images.json' do
      content_type :json
      cache "images:#{params[:keys]}" do
        image_url = get_image_url(params[:keys])
        JSON.dump({ image_url: image_url })
      end
    end

    get '/images/:key.gif' do
      content_type :gif
      image_url = URI.parse(get_image_url(params[:key]))
      Net::HTTP.get_response(image_url).body
    end

    private

    def get_image_url(key)
      SkyMorph::Image.find(key).first.path
    end
  end
end
