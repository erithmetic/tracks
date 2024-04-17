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

    def find_track_by_metadata(metadata)
      album = album_from_metadata metadata
      track = track_from_metadata metadata
      track.album = album
      
      if beats_album = album_from_beats(album.serial)
        album = album.merge(beats_album)
        
        raise "No discogs URL for album #{album.title}" if beats_album.discogs_url.nil?

        album = album.merge(album_from_discogs(beats_album.discogs_url))
        track = album.find_track(track.number)
      end

      track
    end
    
    def track_from_catalog_and_track(catalog_number:, track_number:)
      album = album_from_beats catalog_number
      raise "Album not found: #{catalog_number}" if album.nil?

      album = album.merge(album_from_discogs(album.discogs_url))
      track = album.find_track(track_number)
      raise "Track #{track_number} not found in album #{album.inspect}" if track.nil?

      track
    end

    def album_from_beats(catalog_number)
      beats_albums.find { |a| a.serial == catalog_number }
    end

    def album_from_metadata(metadata)
      Album.new(
        serial: metadata.catalog_number,
        artist: metadata.artist,
        title: metadata.album,
        year: metadata.year,
        tracks: [track_from_metadata(metadata)],
        genres: metadata.genre,
      )
    end

    def track_from_metadata(metadata)
      Track.new(
        number: metadata.track_number,
        label: nil,
        title: metadata.title,
        description: metadata.comment,
      )
    end

    def album_from_discogs(discogs_url)
      discogs_cache.fetch(discogs_url)
    end
  end
end