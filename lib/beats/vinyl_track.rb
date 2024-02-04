require_relative './ffmpeg'

module Beats
  class VinylTrack
    attr_reader :album, :track

    def initialize(album:, track:)
      @album = album
      @track = track
    end

    def source_path
      File.join(album.source_path, track.number.to_s) + '.wav'
    end

    def dest_path
      File.join(album.dest_path, track.filename) + '.wav'
    end

    def tmp_path
      "#{source_path}.tmp.wav"
    end

    def apply_high_pass_filter!
      FFMPEG.apply! source_path, "-af highpass=20"
    end

    def max_volume
      out = FFMPEG.execute "-i \"#{source_path}\" -filter:a volumedetect -f null /dev/null"
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

    def amplify!
      current_volume = max_volume
      adjustment = amplification_amount(current_volume)

      if adjustment == 0.0
        return [current_volume, current_volume]
      else
        FFMPEG.apply! source_path, "-filter:a \"volume=#{adjustment}dB\""
      end

      [current_volume, max_volume]
    end


    def insert_into_library!
      FileUtils.mkdir_p File.dirname(dest_path)
      FileUtils.cp source_path, dest_path
    end
  end
end
