require 'open-uri'

require_relative '../config'
require_relative './sanitize'

module Beats
  class Album
    attr_reader :serial, :artist, :title, :year, :genres, :discogs_url, :tracks

    def initialize(serial:, artist:, title:, year:, genres: [], discogs_url: '', tracks: [])
      @serial = serial
      @artist = artist
      @title = title
      @year = year
      @genres = genres
      @discogs_url = discogs_url
      @tracks = tracks
    end

    def artist_title
      [artist, title].join(' - ')
    end

    def source_path
      File.join SOURCE_PATH, serial, 'cleaned'
    end

    def finalized_path
      File.join SOURCE_PATH, serial, 'finalized'
    end

    def dest_path
      File.join TRACKS_PATH, Sanitize.filename(artist_title)
    end

    def discogs_release
      discogs_url.split('/').last.split('-').first
    end

    def discogs_info
      @discogs_info ||= discogs.get_release discogs_release
    end

    def discogs
      Discogs::Wrapper.new('dj', user_token: ENV.fetch('DISCOGS_USER_TOKEN'))
    end

    def cover_path(ext)
      File.join source_path, "cover.#{ext}"
    end

    def cover_image_path
      if image_uri = discogs_info.images.first&.uri
        ext = image_uri.split('.').last
        path = cover_path(ext)
        URI.open(image_uri) do |image|
          File.open(path, 'w') do |f|
            f.write image.read
          end
        end

        return path
      end
    end
  end
end
