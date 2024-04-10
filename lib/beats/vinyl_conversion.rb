require_relative '../config'
require_relative './destination_track_file'
require_relative './ffmpeg'
require_relative './sanitize'

module Beats
  class VinylConversion
    SOURCE_EXT = '.aiff'

    attr_reader :album, :track, :dest_file

    def initialize(album:, track:)
      @album = album
      @track = track
      @dest_file = DestinationTrackFile.new album: album, track: track, ext: SOURCE_EXT
    end

    def source_path
      File.join(VINYL_PATH, album.serial, 'cleaned', track.number.to_s) + SOURCE_EXT
    end

    def tmp_path
      File.join VINYL_PATH, album.serial, 'tmp', dest_filename + SOURCE_EXT
    end

    def max_volume
      out = FFMPEG.execute "-i \"#{tmp_path}\" -filter:a volumedetect -f null /dev/null"
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
      FileUtils.mkdir_p tmp_path
      FileUtils.cp source_path, tmp_path, preserve: false

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

      FFMPEG.apply! tmp_path, "-c:a pcm_s24be -filter:a \"#{filters.join(', ')}\""

      dest_file.ensure_dest_path!
      FileUtils.cp tmp_path, dest_file.path
      dest_file.write_metadata!
    end
  end
end
