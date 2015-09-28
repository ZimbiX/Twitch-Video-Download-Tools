#!/usr/bin/env ruby

require 'unirest'

require 'shellwords'

def api_video_list_for_channel channel
  api_url = "https://api.twitch.tv/kraken/channels/#{channel}/videos?broadcasts=true&limit=100"
  headers = {
    "Accept" => "application/vnd.twitchtv.v3+json",
    "Client-ID" => IO.read('.twitch-developer-client-id').chomp,
  }
  puts "Querying API..."
  response = Unirest.get api_url, headers: headers
  response.body["videos"]
end

def download_videos videos
  videos.each do |v|
    date = v["recorded_at"].gsub('Z','').gsub('T','_').gsub(':','-')
    url = v["url"]
    title = v["title"]
    id = url.split('/').last
    name = "%s - %s - %s" % [date, id, title]
    download_video_to_folder url, name
  end
end

def download_video_to_folder url, name
  if Dir.exist? name
    puts "SKIPPED - directory already exists: #{name}"
  else
    puts "Downloading: #{name}"
    Dir.mkdir name
    name_escaped = Shellwords.escape name
    Dir.chdir name do
      download_video
    end
  end
end

def download_video
  
end

if __FILE__ == $0
  videos = api_video_list_for_channel ARGV[0]
  # require 'pry'; binding.pry
  download_videos videos
end
