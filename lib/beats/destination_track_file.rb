require_relative './track_file'

module Beats
  class DestinationTrackFile < TrackFile
    EXT = '.aiff'

    def self.each(&blk)
      Dir.glob("#{TRACKS_PATH}/**/*#{EXT}").each do |f|
        dest_track = new path: f, album: album, track: track
        blk.call dest_track
      end
    end

    def initialize(album:, track:)
      super path: nil, album: album, track: track
    end

    def path
      @path ||= File.join(TRACKS_PATH, Sanitize.filename(album.artist_title), filename) + EXT
    end
  end
end