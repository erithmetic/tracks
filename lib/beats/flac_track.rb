require_relative './ffmpeg'

module Beats
  class FlacTrack
    DEST_EXT = 'aiff'

    attr_reader :path

    def initialize(path:)
      @path = path
    end

    def album_name
      parts = path.sub(ALBUMS_PATH, '').split('/')
      if parts.length > 2
        parts[1]
      else
        nil
      end
    end

    def source_filename
      File.basename(path)
    end

    def dest_filename
      File.basename(path).sub(/flac$/, DEST_EXT)
    end

    def source_path
      path
    end

    def dest_path
      File.join(*[TRACKS_PATH, album_name, dest_filename].compact)
    end

    def cover_path
      File.join(File.dirname(source_path), 'cover.jpg')
    end

    def convert!
      FileUtils.mkdir_p File.dirname(dest_path)

      FFMPEG.apply! source_path, "-c:a pcm_s24be -id3v2_version 3 -write_id3v2 1 \"#{dest_path}\""

      # if File.exist?(cover_path)
      #   FFMPEG.apply! dest_path, "-i \"#{cover_path}\"  -c copy -map 0 -map 1 -id3v2_version 3 -write_id3v2 1"
      # end
    end
  end
end