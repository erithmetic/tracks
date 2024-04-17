require_relative '../config'
require_relative './destination_track_file'
require_relative './ffmpeg'

module Beats
  class FlacConversion
    DEST_EXT = '.aiff'

    attr_reader :source_file, :dest_file

    def self.from_file(library:, path:)
      cover_image_path = File.join(File.dirname(path), 'cover.jpg')
      source_file = TrackFile.read library: library, path: path, cover_image_path: cover_image_path
      new source_file: source_file
    end

    def initialize(source_file:)
      @source_file = source_file
      @dest_file = DestinationTrackFile.new album: source_file.album, track: source_file.track, ext: AIFF_EXT
    end

    def process!
      return false if dest_file.exist? || source_file.album.serial.nil?

      dest_file.ensure_dest_path!

      FFMPEG.convert! source_file.path, "-y -c:a pcm_s24be -id3v2_version 3 -write_id3v2 1", dest_file.path
      dest_file.write_cover_image!
      dest_file.write_metadata!

      true
    end
  end
end