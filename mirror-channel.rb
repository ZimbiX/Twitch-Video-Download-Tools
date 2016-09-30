#!/usr/bin/env ruby

require_relative 'twitch-downloader.rb'

class MirrorTwitchChannel
  def initialize client_id
    @downloader = TwitchDownloader.new client_id
  end

  def mirror channel
    @channel = channel
    videos = api_video_list
    puts "#{videos.size} videos available"
    videos.reverse.each do |v|
      date = v["recorded_at"].gsub('Z','').gsub('T','_').gsub(':','-')
      url = v["url"]
      title = v["title"].gsub(%r{[/:]},'_')
      id = url.split('/').last
      name = "%s - %s - %s" % [date, id, title]
      download_video_to_folder url, name, v
    end
  end

private
  def api_video_list
    api_url = "https://api.twitch.tv/kraken/channels/#{@channel}/videos?broadcasts=true&limit=100"
    puts "Querying API..."
    response = @downloader.fetch api_url
    response["videos"]
  end

  def download_video_to_folder url, name, metadata
    puts "Downloading: #{name}"
    puts "=" * 80
    if Dir.exist? name
      puts "Will be attempting to resume - directory already exists"
    else
      Dir.mkdir name
    end
    Dir.chdir name do
      File.open("metadata.json", 'w') { |f| f.write metadata.to_json }
      @downloader.download url
    end
  end
end

if __FILE__ == $0
  if ARGV.length != 1 or ['--help', '-h'].include? ARGV[0]
    puts "Usage: #{__FILE__} <channel_name>"
    exit
  end
  client_id = IO.read(File.expand_path('.twitch-developer-client-id', File.dirname(__FILE__))).chomp
  MirrorTwitchChannel.new(client_id).mirror ARGV[0]
end
