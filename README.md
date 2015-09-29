# Twitch Video Download Tools

Command-line tools for downloading videos from [Twitch.tv](http://www.twitch.tv).

## Twitch Downloader

A command-line tool and library that can be used to download a Twitch.tv VOD. It is compatible with Twitch's new system of splitting videos into tiny chunks.

Resuming downloads is supported and happens automatically when you restart the script, but it only works correctly if you keep the accompanying chunk list files intact.

### Setup

Install [Ruby](https://www.ruby-lang.org/en/) (on Windows, use (RubyInstaller)[http://rubyinstaller.org/]), and make sure it's in your system's PATH variable.

[Download](https://github.com/ZimbiX/Twitch-Video-Download-Tools/archive/master.zip) and extract these tools.

Then open a terminal window into that folder (on Windows, Shift + Right-click in the folder > "Open command window here") and run:

    gem install bundler
    bundle

to install the Ruby gems that these tools depend on.

When running a Ruby program on Windows, replace `./` with `ruby `

### Usage

    ./twitch-downloader.rb URL

## Mirror Channel

This tool utilises the downloader library to download all of the currently available past broadcasts for a channel. As this may take some time depending on your internet connection, VODs are downloaded in descending order of age.

You can keep running this script to keep your collection up-to-date. Older broadcasts and ones which have since been removed from Twitch will be kept.

### Setup

#### General

See above.

#### Twitch API token

To avoid rate limiting when acquiring a channel's video lists, you need to supply a application Client ID to the Twitch API.

[Create an API token](http://www.twitch.tv/kraken/oauth2/clients/new) using your account on Twitch, supplying a unique name, and `http://localhost` for the Redirect URI.

Copy the generated Client ID into a plain text file `.twitch-developer-client-id` in the same folder.

### Usage

    ./mirror-channel.rb CHANNEL_NAME

or, to run in the background:

    nohup ./mirror-channel.rb CHANNEL_NAME > log.txt &

## Some technical details

### How the video downloading works

See [Adam Bronte's blog post](https://adam.bronte.me/2015/05/29/downloading-twitch-tv-vods/)

### Resuming downloads

My first thought for testing whether a download is complete was to check the duration of the video, and compare it to the length specified by the Twitch API, allowing a small margin of error.

A VOD is downloaded by grabbing each ~600 KB chunk of MPEG-TS video and concatenating them into one video file. FFmpeg does not recognise the resulting video as valid, and so it not able to test the length.

MediaInfo on the other hand, *is* able to determine the length, but installing this as a dependency is not trivial.

After investigating these, I realised that not only should it detect an imcomplete download, but it would also need a way to resume that download. Chunk information would have to be kept.

### Chunk HTTP 404s

For one VOD, I came across a series of chunks whose URLs, for whatever reason, only gave 404 errors. I don't know why this is, or if it has any effect on the produced video file. If applicable, the script keeps a log of a video's failed URLs beside its other chunk list files, in `chunk_list_failed.txt`.

## Why create this?

Quite simply, **Twitch's VOD service is garbage**. Often, I've encountered unbearably frequent pauses due to buffering - no matter what quality is selected. It used to be that when paused, it would buffer up to the end of the current 30 minute block, but now it only buffers about 30 seconds! Plus, now that videos are purged after a couple of months, I wanted to make sure that I would be able to see the streams before they're gone for good.

Those are the main reasons, but there's also the lack of keyboard shortcuts - No key to go back a few seconds? Come on - and a super simple one: you can't even see what time of day they streamed at!

**If you find this and you're a Twitch admin, please do consider fixing the above issues before breaking these downloading tools. Thanks =)**
