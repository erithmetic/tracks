require_relative './album'
require_relative './discogs_cache'
require_relative './track'

module Beats
  class Library
    attr_reader :beats_albums, :discogs_cache

    def self.load
      new beats_albums: Beats.parse_albums
    end

    def initialize(beats_albums: [])
      @beats_albums = beats_albums
      @discogs_cache = DiscogsCache.new
    end

    def track_from_metadata(metadata)
      album = album_from_metadata metadata
      if beats_album = album_from_beats(metadata[:CATALOGNUMBER])
        album = album.merge(beats_album)
        album = album.merge(album_from_discogs(beats_album.discogs_url))
      end
      track = album.find_track(metadata[:track])
      raise "Track not found: #{metadata.inspect}" if track.nil?

      track
    end
    
    def track_from_catalog_and_track(catalog_number:, track_number:)
      album = album_from_beats catalog_number
      album = album.merge(album_from_discogs(album.discogs_url))
      track = album.find_track(track_number)
      raise "Track not found: #{metadata.inspect}" if track.nil?

      track
    end

    def album_from_beats(catalog_number)
      beats_albums.find { |a| a.serial == catalog_number }
    end

    def album_from_metadata(metadata)
      Album.new(
        serial: metadata[:CATALOGNUMBER],
        artist: metadata[:ARTIST],
        title: metadata[:ALBUM],
        year: metadata[:DATE],
        tracks: [build_track_from_metadata(metadata)]
      )
    end

    def build_track_from_metadata(metadata)
      Track.new(
        number: metadata[:track],
        label: nil,
        title: metadata[:TITLE],
        description: metadata[:comment],
      )
    end

    def album_from_discogs(discogs_url)
      discogs_cache.fetch(discogs_url)
    end
  end
end