require_relative '../config'
require_relative './destination_track_file'
require_relative './ffmpeg'
require_relative './track_file'
require_relative './sanitize'
require_relative './vinyl_track_file'

module Beats
  class VinylConversion
    SOURCE_EXT = '.aiff'

    attr_reader :source_file, :dest_file, :album, :track

    def self.from_file(library:, catalog_number:, track_number:, path:)
      track = library.track_from_catalog_and_track catalog_number: catalog_number, track_number: track_number
      new track: track, path: path
    end

    def initialize(track:, path:)
      @track = track
      @album = track.album
      @source_file = TrackFile.new path: path, album: album, track: track
      @dest_file = VinylTrackFile.new album: album, track: track
    end

    def process!(force: false)
      dest_file.ensure_dest_path!
      return if !force && dest_file.exist?

      FileUtils.cp source_file.path, dest_file.path

      apply_ffmpeg_filters!([
        'highpass=20',
        'areverse',
        'atrim=start=0',
        'silenceremove=start_periods=1:start_silence=0:start_threshold=0.02',
        'areverse',
        'atrim=start=0',
        'silenceremove=start_periods=1:start_silence=0:start_threshold=0.02',
      ])
      apply_ffmpeg_filters!(['dynaudnorm=p=0.95:altboundary=1'])

      dest_file.write_cover_image!
      dest_file.write_metadata!
    end

    def apply_ffmpeg_filters!(filters = [])
      FFMPEG.modify! dest_file.path, "-c:a pcm_s24be -ar 44100 -filter:a \"#{filters.join(', ')}\""
    end
  end
end
