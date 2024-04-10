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
      File.join(TRACKS_PATH, Sanitize.filename(album.artist_title), filename) + EXT
    end

    def filename
      track_title = Sanitize.filename(track.title)
      [Sanitize.filename(album.artist_title), track.number.to_s.rjust(2,'0'), track_title].join(' - ')
    end

    def exist?
      File.exist? path
    end

    def ensure_dest_path!
      FileUtils.mkdir_p File.dirname(path)
    end
  end
end