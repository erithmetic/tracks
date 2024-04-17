require_relative '../config'
require_relative './track_file'

module Beats
  class VinylTrackFile < TrackFile
    def initialize(album:, track:)
      super path: nil, album: album, track: track, ext: AIFF_EXT
    end

    def path
      @path ||= File.join(DIGITAL_PATH, Sanitize.filename(album.artist_title), filename) + AIFF_EXT
    end
  end
end