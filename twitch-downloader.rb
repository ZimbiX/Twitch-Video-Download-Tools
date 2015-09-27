#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'json'

def fetch uri, name = nil
  puts "Fetching #{name} from: #{uri}" if name
  RestClient.get(uri)
end

if __FILE__ == $0

  if ARGV.length != 1
    puts "Usage: download.rb <url>"
    exit
  end

  url = ARGV[0]

  puts "Downloading #{url}"

  vod_id = url.split("/")[-1]

  token_url = "https://api.twitch.tv/api/vods/#{vod_id}/access_token?as3=t"
  token = JSON.parse(fetch(token_url, "token"))

  qualities_list_url = "http://usher.justin.tv/vod/#{vod_id}?nauthsig=#{token["sig"]}&nauth=#{token["token"]}"
  qualities_list = fetch(qualities_list_url, "qualities list")

  chunk_list_url = qualities_list.split("\n")[3].gsub(%r{/(high|medium|low|mobile)/},'/chunked/')
  chunk_list = fetch(chunk_list_url, "chunk list").split("\n").select { |c| c[0] != '#' && c != '' }

  dl_url = "http://#{chunk_list_url.split("/")[2..-2].join("/")}"
  pct_format = "%2.3f%"

  open("#{vod_id}.ts", "wb") do |file|
    list_size = chunk_list.size
    puts "Downloading #{list_size} video parts..."
    chunk_list.each_with_index do |part, i|
      url = "#{dl_url}/#{part}"
      pct = pct_format % (i / list_size.to_f)
      progress = "%4d" % (i+1) + " of #{list_size}"
      puts "  #{pct} - #{progress}: #{url}"
      resp = fetch(url)
      file.write(resp.body)
    end
  end

  puts pct_format % 100 + " - Done"

end
