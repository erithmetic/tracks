require_relative '../config'

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

    def dest_path
      File.join TRACKS_PATH, artist_title
    end

    def discogs_release
      discogs_url.split('/').last.split('-').first
    end
  end
end
