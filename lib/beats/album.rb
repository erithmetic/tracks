require 'open-uri'

require_relative '../config'
require_relative './sanitize'

module Beats
  class Album
    attr_reader(
      :serial,
      :artist,
      :title,
      :year,
      :genres,
      :discogs_url,
      :tracks,
      :cover_image_path,
      :all_artists,
      :labels
    )


    def self.from_metadata(albums:, metadata:, source_path:)
      new(serial: nil, artist: nil, title: nil, year: nil)
    end

    def initialize(serial:, artist:, title:, year:, genres: [], discogs_url: '', tracks: [], all_artists: [], labels: [], cover_image_path: nil)
      @serial = serial
      @artist = artist
      @title = title
      @year = year
      @genres = genres || []
      @discogs_url = discogs_url
      @tracks = tracks
      tracks.each { |t| t.album = self }
      @all_artists = all_artists || []
      @labels = labels
      @cover_image_path = cover_image_path
    end

    def artist_title
      [artist, title].join(' - ')
    end

    def find_track(num)
      tracks.find { |t| t.number == num.to_i }
    end

    def merge(other)
      self.class.new(
        serial: serial || other.serial,
        artist: artist || other.artist,
        title: title || other.title,
        year: year || other.year,
        genres: genres || other.genres,
        discogs_url: discogs_url || other.discogs_url,
        tracks: merge_tracks(other.tracks),
        all_artists: (all_artists + other.all_artists).uniq,
        labels: (labels + other.labels).uniq,
        cover_image_path: cover_image_path || other.cover_image_path,
      )
    end

    def merge_tracks(other_tracks)
      trackpack = {}
      (tracks + other_tracks).each do |track|
        if matched_track = trackpack[track.number]
          trackpack[track.number] = matched_track.merge(track)
        else
          trackpack[track.number] = track
        end
      end

      trackpack.values_at(*trackpack.keys.sort)
    end
  end
end
