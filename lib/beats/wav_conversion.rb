require_relative '../config'
require_relative './destination_track_file'
require_relative './ffmpeg'
require_relative './track_file'

module Beats
  class WavConversion
    attr_reader :source_file, :dest_file, :album, :track

    def self.from_file(library:, path:)
      cover_image_path = File.join(File.dirname(path), 'cover.jpg')
      source_file = TrackFile.read library: library, path: path, cover_image_path: cover_image_path
      new source_file: source_file
    end

    def initialize(source_file:)
      @source_file = source_file
      @dest_file = DestinationTrackFile.new album: source_file.album, track: source_file.track, ext: AIFF_EXT
    end

    def process!(force: false)
      dest_file.ensure_dest_path!
      return if !force && dest_file.exist?

      FFMPEG.execute source_file.path, "-c:a pcm_s24be -ar 44100", dest_file.path

      dest_file.write_cover_image!
      dest_file.write_metadata!
    end
  end
end
