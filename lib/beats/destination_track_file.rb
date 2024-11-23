require_relative '../config'
require_relative './track_file'

module Beats
  class DestinationTrackFile < TrackFile
    def initialize(album:, track:, ext: AIFF_EXT)
      super path: nil, album: album, track: track, ext: ext
    end

    def filename
      return @filename unless @filename.nil?

      track_title = Sanitize.filename(track.title.to_s)
      @filename = [track.number.to_s.rjust(2,'0'), track_title].join(' - ')
    end

    def path
      @path ||= File.join(TRACKS_PATH, Sanitize.filename(album.artist_title), filename) + ext
    end
  end
end