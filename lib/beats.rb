require 'csv'

require_relative './beats/album'
require_relative './beats/flac_track'
require_relative './beats/track'
require_relative './beats/vinyl_track'

module Beats
  BEATS_CSV_PATH=File.expand_path('../../beats.csv', __FILE__)

  def self.each_vinyl_track(&blk)
    albums = parse_albums

    albums.each do |album|
      album.tracks.each do |track|
        track_file = VinylTrack.new album: album, track: track
        blk.call track_file
      end
    end
  end

  def self.each_flac(&blk)
    Dir.glob("#{ALBUMS_PATH}/**/*.flac").each do |f|
      flac = Beats::FlacTrack.new path: f
      blk.call flac
    end
  end

  def self.parse_albums
    albums = []

    CSV.open BEATS_CSV_PATH, headers: true do |csv|
      csv.each do |row|
        serial = row['Serial'] or raise "no serial for #{row}"

        track_count = 0
        tracks = row['Notes'].split(',').map do |line|
          parts = line.split(' ')
          label = parts.shift
          description = parts.join ' '
          track_count += 1
          Track.new number: track_count, label: label, description: description
        end

        album = Album.new(
          serial: serial,
          artist: row['Artist'],
          title: row['Album'],
          year: row['Year'],
          genres: (row['Genres'] || '').split(/,\s*/),
          discogs_url: row['URL'],
          tracks: tracks
        )

        albums << album
      end
    end

    albums
  end
end
