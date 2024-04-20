
module Beats
  class Metadata
    FFMPEG_METADATA_KEYS = %i{ALBUM ARTIST DATE description genre TITLE track CATALOGNUMBER album_artist comment}
    FFPROBE_METADATA_KEYS = ['title', 'artist', 'track' 'album', 'ID3v1 Comment']

    def self.from_ffprobe(json)
      tags = json.fetch('format', {}).fetch('tags', {})
      new(
        catalog_number: tags['CATALOGNUMBER'],
        album: tags['album'],
        artist: tags['artist'],
        title: tags['title'],
        year: tags['date'],
        track_number: tags['track'],
        comment: tags['ID3v1 Comment'],
        genre: tags['genre']&.split(',') || [],
      )
    end

    attr_accessor(
      :catalog_number,
      :album,
      :artist,
      :title,
      :year,
      :track_number,
      :description,
      :comment,
      :genre,
    )

    def initialize(
      catalog_number: nil,
      album: nil,
      artist: nil,
      title: nil,
      year: nil,
      track_number: nil,
      description: nil,
      comment: nil,
      genre: nil)
      @catalog_number = catalog_number
      @album = album
      @artist = artist
      @title = title
      @year = year
      @track_number = track_number
      @description = description
      @comment = comment
      @genre = genre
    end

    def to_ffmpeg_metadata
      {
        ALBUM: album,
        ARTIST: artist, 
        DATE: year,
        description: description,
        genre: genre,
        TITLE: title,
        track: track_number,
        CATALOGNUMBER: catalog_number,
        comment: comment,
      }
    end
  end
end