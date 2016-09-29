#!/usr/bin/env ruby

require 'unirest'

require_relative 'twitch-downloader.rb'

module MirrorTwitchChannel
  module_function

  def mirror_channel channel
    videos = api_video_list_for_channel channel
    download_videos videos.reverse
  end

  def api_video_list_for_channel channel
    api_url = "https://api.twitch.tv/kraken/channels/#{channel}/videos?broadcasts=true&limit=100"
    client_id = IO.read(File.expand_path('.twitch-developer-client-id', File.dirname(__FILE__))).chomp
    headers = {
      "Accept" => "application/vnd.twitchtv.v3+json",
      "Client-ID" => client_id,
    }
    puts "Querying API..."
    response = Unirest.get api_url, headers: headers
    response.body["videos"]
  end

  def download_videos videos
    puts "#{videos.size} videos available"
    videos.each do |v|
      date = v["recorded_at"].gsub('Z','').gsub('T','_').gsub(':','-')
      url = v["url"]
      title = v["title"].gsub(%r{[/:]},'_')
      id = url.split('/').last
      name = "%s - %s - %s" % [date, id, title]
      download_video_to_folder url, name, v
    end
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
      TwitchDownloader.download_video_by_url url
    end
  end

end

if __FILE__ == $0
  if ARGV.length != 1 or ['--help', '-h'].include? ARGV[0]
    puts "Usage: #{__FILE__} <channel_name>"
    exit
  end
  # require 'pry'; binding.pry
  MirrorTwitchChannel.mirror_channel ARGV[0]
end
