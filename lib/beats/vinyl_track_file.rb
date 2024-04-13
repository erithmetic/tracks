require_relative './track_file'

module Beats
  class VinylTrackFile < TrackFile
    EXT = '.aiff'
    
    def initialize(album:, track:)
      super path: nil, album: album, track: track
    end

    def path
      @path ||= File.join(DIGITAL_PATH, Sanitize.filename(album.artist_title), filename) + EXT
    end
  end
end