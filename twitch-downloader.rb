#!/usr/bin/env ruby

require 'rest-client'

require_relative 'ruby-progressbar-twoline/ruby-progressbar-twoline.rb'

require 'json'
require 'uri'

module TwitchDownloader
  module_function

  def download_video_by_url url
    puts "Downloading #{url}"
    vod_id = url.split("/")[-1]

    token_url = "https://api.twitch.tv/api/vods/#{vod_id}/access_token?as3=t"
    token = JSON.parse(fetch(token_url, "token"))

    qualities_list_url = "http://usher.justin.tv/vod/#{vod_id}?nauthsig=#{token["sig"]}&nauth=#{token["token"]}"
    qualities_list = fetch(qualities_list_url, "qualities list")

    chunk_list_url = qualities_list.split("\n")[3].gsub(%r{/(high|medium|low|mobile)/},'/chunked/')
    chunk_list = fetch(chunk_list_url, "chunk list").split("\n").select { |c| c[0] != '#' && c != '' }
    chunk_list = chunk_list_io chunk_list

    dl_url = "http://#{chunk_list_url.split("/")[2..-2].join("/")}"
    download_video_chunks dl_url, chunk_list, vod_id
  end

  def fetch uri, name = nil
    puts "Fetching #{name} from: #{uri}" if name
    RestClient.get(URI.escape(uri))
  end

  def chunk_list_io chunk_list
    if File.exist? "chunk_list.txt"
      chunk_list_prev = IO.read("chunk_list.txt").split("\n")
      if chunk_list != chunk_list_prev
        puts "WARNING: chunk list differs from last attempt - using previous list"
        File.open("chunk_list_new_conflicted.txt", 'w') { |f| f.write chunk_list.join("\n") }
        chunk_list = chunk_list_prev
      end
    else
      File.open("chunk_list.txt", 'w') { |f| f.write chunk_list.join("\n") }
    end
  end

  def download_video_chunks dl_url, chunk_list, filename
    chunk_list = try_resume_chunk_list chunk_list, filename
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
        pct = progressbar.percentage_completed_with_precision
        progressbar.log("#{pct}% #{url}")
        begin
          response = fetch(url)
          file.write(response.body)
          File.open("chunk_list_done.txt", 'a') { |f| f.puts part }
        rescue => e
          progressbar.log("Exception encountered: #{e}")
          progressbar.log(response.inspect)
          progressbar.log(e.backtrace)
          File.open("chunk_list_failed.txt", 'a') { |f| f.puts part }
          progressbar.log("Continuing to download the rest of the video")
        end
        progressbar.increment
      end
    end
  end

  def try_resume chunk_list, filename
    return chunk_list unless File.exist? "chunk_list_done.txt"
    chunk_list_tried_prev = IO.read("chunk_list_done.txt").split("\n")
    if File.exist? "chunk_list_failed.txt"
      chunk_list_tried_prev += IO.read("chunk_list_failed.txt").split("\n")
    end
    return chunk_list unless chunk_list_tried_prev.size >= 1
    return [] unless chunk_list_tried_prev.size < chunk_list.size # Already finished
    next_chunk = chunk_list_tried_prev.size
    chunk_list_resume = chunk_list[next_chunk..-1]
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
