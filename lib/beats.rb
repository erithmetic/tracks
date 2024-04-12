require 'csv'

require_relative './beats/album'
require_relative './beats/flac_conversion'
require_relative './beats/track'
require_relative './beats/track_file'
require_relative './beats/vinyl_conversion'

module Beats
  BEATS_CSV_PATH=File.expand_path('../../beats.csv', __FILE__)

  def self.each_vinyl_track(&blk)
    Dir.glob("#{VINYL_PATH}/*").each do |album_dir|
      next if album_dir =~ /^\./ || !File.directory?(album_dir)
      catalog_number = File.basename album_dir

      Dir.glob(File.join(album_dir, 'cleaned', '*.aiff')).each do |file|
        track_number = File.basename(file, '*.aiff')
        blk.call catalog_number, track_number, file
      end
    end
  end

  def self.each_flac(&blk)
    Dir.glob("#{DIGITAL_PATH}/**/*.flac").each do |f|
      blk.call f
    end
  end

  def self.each_output_track(&blk)
    albums = parse_albums

    DestinationTrackFile.each do |track|
      blk.call track
    end
  end

  def self.parse_albums
    albums = []

    CSV.open BEATS_CSV_PATH, headers: true do |csv|
      csv.each do |row|
        serial = row['Serial'] or raise "no serial for #{row}"

        track_count = 0
        tracks = row['Notes'].to_s.split(',').map do |line|
          parts = line.split(' ')
          label = parts.shift
          description = parts.join ' '
          track_count += 1
          Track.new number: track_count, label: label, description: description, title: nil
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
