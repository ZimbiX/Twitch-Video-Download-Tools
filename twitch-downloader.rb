#!/usr/bin/env ruby

require 'rest-client'

require_relative 'ruby-progressbar-twoline/ruby-progressbar-twoline.rb'

require 'json'
require 'uri'

module TwitchDownloader

  def download_video_by_url url
    puts "Downloading #{url}"
    vod_id = url.split("/")[-1]

    token_url = "https://api.twitch.tv/api/vods/#{vod_id}/access_token?as3=t"
    token = JSON.parse(fetch(token_url, "token"))

    qualities_list_url = "http://usher.justin.tv/vod/#{vod_id}?nauthsig=#{token["sig"]}&nauth=#{token["token"]}"
    qualities_list = fetch(qualities_list_url, "qualities list")

    chunk_list_url = qualities_list.split("\n")[3].gsub(%r{/(high|medium|low|mobile)/},'/chunked/')
    chunk_list = fetch(chunk_list_url, "chunk list").split("\n").select { |c| c[0] != '#' && c != '' }

    dl_url = "http://#{chunk_list_url.split("/")[2..-2].join("/")}"
    download_video_chunks dl_url, chunk_list, vod_id
  end

  def fetch uri, name = nil
    puts "Fetching #{name} from: #{uri}" if name
    RestClient.get(URI.escape(uri))
  end

  def download_video_chunks dl_url, chunk_list, filename
    open("#{filename}.ts", "wb") do |file|
      list_size = chunk_list.size
      progressbar = ProgressBar.create(
        format: "%t %b%i\n%a %E Processed: %c of %C, %P%",
        total: list_size,
        remainder_mark: '･',
      )
      puts "Downloading #{list_size} video parts..."
      chunk_list.each_with_index do |part, i|
        url = "#{dl_url}/#{part}"
        progressbar.log(url)
        response = fetch(url)
        file.write(response.body)
        progressbar.increment
      end
    end
  end

end

if __FILE__ == $0
  if ARGV.length != 1 or ['--help', '-h'].include? ARGV[0]
    puts "Usage: #{__FILE__} <url>"
    exit
  end
  url = ARGV[0]
  TwitchDownloader.download_video_by_url url
end
