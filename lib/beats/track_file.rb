require_relative './ffmpeg'

module Beats
  class TrackFile
    METADATA_KEYS = %i{ALBUM ARTIST DATE description genre TITLE track CATALOGNUMBER album_artist comment}
    
    attr_reader :path, :album, :track, :metadata, :cover_image_path

    def self.read(library:, path:, cover_image_path: nil)
      metadata = FFMPEG.info path
      track = library.track_from_metadata metadata
      new path: path, album: track.album, track: track, cover_image_path: cover_image_path
    end

    def initialize(path:, album:, track:, cover_image_path: nil)
      @path = path
      @album = album
      @track = track
      @cover_image_path = cover_image_path || track.album.cover_image_path
      @metadata = {}
    end

    def exist?
      File.exist? path
    end

    def ext
      path.split('.').last
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

      return {
        album: album.title,
        artist: album.artist,
        date: album.year,
        description: comments,
        genre: album.genres.join(', '),
        title: track.title,
        track: track.number,
        CATALOGNUMBER: album.serial,
      }
    end

    def ensure_dest_path!
      FileUtils.mkdir_p File.dirname(path)
    end

    def write_metadata!
      FFMPEG.write_id3! path, metadata
    end

    def write_cover_image!
      FFMPEG.write_cover_image! path, cover_image_path
    end
  end
end
