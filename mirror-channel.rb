#!/usr/bin/env ruby

require 'unirest'

if __FILE__ == $0
  channel = ARGV[0]
  api_url = "https://api.twitch.tv/kraken/channels/#{channel}/videos?broadcasts=true&limit=100"
  headers = {
    "Accept" => "application/vnd.twitchtv.v3+json",
    "Client-ID" => IO.read('.twitch-developer-client-id').chomp,
  }
  puts "Querying API..."
  response = Unirest.get(api_url, headers: headers)
  videos = response.body
end
