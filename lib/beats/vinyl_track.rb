require 'shellwords'

require_relative '../config'
require_relative './ffmpeg'
require_relative './sanitize'

module Beats
  class VinylTrack
    SOURCE_EXT = '.aiff'

    attr_reader :album, :track

    def initialize(album:, track:)
      @album = album
      @track = track
    end

    def source_path
      File.join(album.source_path, track.number.to_s) + SOURCE_EXT
    end

    def finalized_path
      File.join(album.finalized_path, dest_filename) + SOURCE_EXT
    end

    def dest_path
      File.join(album.dest_path, dest_filename) + SOURCE_EXT
    end
    
    def dest_filename
      [Sanitize.filename(album.artist_title), track.number, track_title].join(' - ')
    end

    def tmp_path
      "#{finalized_path}.tmp#{SOURCE_EXT}"
    end

    def track_title
      Sanitize.filename(album.discogs_info.tracklist[track.number - 1].title)
    end

    def max_volume
      out = FFMPEG.execute "-i \"#{finalized_path}\" -filter:a volumedetect -f null /dev/null"
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

    def init
      FileUtils.mkdir_p album.finalized_path
      FileUtils.cp source_path, finalized_path, preserve: false
    end

    def apply_hpf_and_amplify!
      current_volume = max_volume
      adjustment = amplification_amount(current_volume)

      filters = [
        'highpass=20'
      ]

      if adjustment == 0.0
        return [current_volume, current_volume]
      else
        filters << "volume=#{adjustment}dB"
      end

      FFMPEG.apply! finalized_path, "-c:a pcm_s24be -filter:a \"#{filters.join(', ')}\""

      [current_volume, max_volume]
    end

    def insert_into_library!
      FileUtils.mkdir_p File.dirname(dest_path)
      FileUtils.cp finalized_path, dest_path
    end

    def tag!
      artists = album.discogs_info.artists.map(&:name)
      labels = album.discogs_info.labels.map(&:name)

      comments = [
        "Artists: #{artists.join(',')}",
        "Labels: #{labels.join(', ')}",
        "Moods: #{track.description}",
      ].join("\n")

      metadata = {
        album: album.title,
        artist: album.artist,
        date: album.year,
        description: comments,
        genre: album.genres.join(', '),
        title: track_title,
        track: track.number,
      }

      cover_image_command = if cover_image = album.cover_image_path
        "-i \"#{cover_image}\"  -c copy -map 0 -map 1"
      end

      metadata_commands = metadata.inject("") do |list, (key, value)|
        list = list + "-metadata #{key}=\"#{value.to_s.gsub("\"","\\\"")}\" "
      end

      FFMPEG.apply! finalized_path, "#{cover_image_command} #{metadata_commands} -id3v2_version 3 -write_id3v2 1"
    end
  end
end
