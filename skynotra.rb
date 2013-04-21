require 'bundler'
require 'digest/sha1'
require 'fog'
require 'json'
require 'net/http'
require 'redis'
require 'uri'

Bundler.require if defined?(Bundler)

before do
  $redis = Redis.new
  $s3    = Fog::Storage.new({
    provider:              'AWS', 
    aws_access_key_id:     ENV['AWS_ACCESS_KEY_ID'], 
    aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  })
  $s3_dir = $s3.directories.create key: 'skynotra', public: true
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

    get '/images.gif' do
      sha = Digest::SHA1.hexdigest(params[:keys])
      file = $s3_dir.files.get(sha) || begin
        puts "Downloading image ..."
        image_url = URI.parse(get_image_url(params[:keys]))
        image = Net::HTTP.get_response(image_url).body

        # Cache image in S3
        s3_file = $s3_dir.files.new({
          key:    sha,
          body:   image,
          public: true
        })
        s3_file.save
        s3_file
      end
      redirect file.public_url
    end

    private

    def get_image_url(key)
      SkyMorph::Image.find(key).first.path
    end
  end
end
