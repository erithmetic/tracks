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
      new track: track
    end

    def initialize(track:)
      @track = track
      @album = track.album
      source_path = File.join(VINYL_PATH, album.serial, 'cleaned', track.number.to_s) + SOURCE_EXT
      @source_file = TrackFile.new path: source_path, album: album, track: track
      @dest_file = VinylTrackFile.new album: album, track: track
    end

    def max_volume
      out = FFMPEG.execute dest_file.path, "-filter:a volumedetect -f null", "/dev/null"
      out.match(/max_volume: (-?\d+\.\d+)/)[1].to_f
    end

    def amplification_amount(current_volume)
      if current_volume == MAX_VOLUME
        0
      elsif current_volume < MAX_VOLUME
        current_volume.abs - MAX_VOLUME.abs
      else
        -1 * current_volume + MAX_VOLUME
      end
    end

    def process!
      dest_file.ensure_dest_path!
      return if dest_file.exist?

      FileUtils.cp source_file.path, dest_file.path

      filters = []
      current_volume = max_volume
      adjustment = amplification_amount(current_volume)
      changes = [current_volume, current_volume]
      if adjustment != 0.0
        filters << "volume=#{adjustment}dB"
        changes = [current_volume, current_volume + adjustment]
      end

      filters += [
        'highpass=20',
        'areverse',
        'atrim=start=0',
        'silenceremove=start_periods=1:start_silence=0:start_threshold=0.02',
        'areverse',
        'atrim=start=0',
        'silenceremove=start_periods=1:start_silence=0:start_threshold=0.02'
      ]

      FFMPEG.modify! dest_file.path, "-c:a pcm_s24be -filter:a \"#{filters.join(', ')}\""
      dest_file.write_cover_image!
      dest_file.write_metadata!
    end
  end
end
