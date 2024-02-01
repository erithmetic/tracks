require 'csv'

module Beats
  BEATS_CSV_PATH=File.expand_path('../../beats.csv', __FILE__)

  def self.each_album(&blk)
    albums = parse_albums

    albums.each do |album|
      blk.call album
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
      File.join SOURCE_PATH, serial, 'final'
    end

    def dest_path
      File.join TRACKS_PATH, artist_title
    end
  end

  class Track
    attr_reader :number, :label, :description

    def initialize(number:, label:, description:)
      @number = number
      @label = label
      @description = description
    end

    def filename
      [number, label].join(' - ')
    end
  end
end
