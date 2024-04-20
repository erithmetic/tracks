require_relative './ffmpeg'
require_relative './metadata'
require_relative './sanitize'

module Beats
  class TrackFile    
    attr_reader :path, :album, :track, :metadata, :cover_image_path, :ext

    def self.read(library:, path:, cover_image_path: nil)
      metadata = FFMPEG.info path
      track = library.find_track_by_metadata(metadata) or raise "Track not found for #{path}"
      new path: path, album: track.album, track: track, cover_image_path: cover_image_path, ext: '.' + path.split('.').last
    end

    def initialize(path:, album:, track:, ext: nil, cover_image_path: nil)
      @path = path
      @album = album
      @track = track
      @ext = ext || path.split('.').last
      @cover_image_path = cover_image_path || track.album.cover_image_path
    end

    def exist?
      File.exist? path
    end

    def dirname
      File.dirname path
    end

    def filename
      return @filename unless @filename.nil?

      track_title = Sanitize.filename(track.title.to_s)
      @filename = [Sanitize.filename(album.artist_title), track.number.to_s.rjust(2,'0'), track_title].join(' - ')
    end

    def album_name
      parts = path.sub(DIGITAL_PATH, '').split('/')
      if parts.length > 2
        parts[1]
      else
        nil
      end
    end

    def metadata
      comments = [
        "Artists: #{album.all_artists.join(',')}",
        "Labels: #{album.labels.join(', ')}",
        track.description,
      ].join("\n")

      return Metadata.new(
        catalog_number: album.serial,
        album: album.title,
        artist: album.artist,
        title: track.title,
        year: album.year,
        track_number: track.number,
        description: comments,
        genre: album.genres&.join(', ')
      )
    end

    def ensure_dest_path!
      FileUtils.mkdir_p File.dirname(path)
    end

    def write_metadata!
      if ext == '.mp3'
        FFMPEG.write_mp3_id3! path, metadata
      else
        FFMPEG.write_id3! path, metadata
      end
    end

    def write_cover_image!
      FFMPEG.write_cover_image! path, cover_image_path
    end
  end
end
