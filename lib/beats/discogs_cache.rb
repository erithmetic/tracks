require_relative './album'
require_relative './track'

module Beats
  class DiscogsCache
    attr_reader :path, :discogs

    def initialize
      @path = File.join Dir.pwd, '.cache'
      @discogs = Discogs::Wrapper.new('dj', user_token: ENV.fetch('DISCOGS_USER_TOKEN'))

      FileUtils.mkdir_p path
    end
  
    def fetch(url)
      release = url.split('/').last.split('-').first

      info = fetch_file(release) || fetch_discogs(release)

      all_artists = info.artists.map(&:anv)
      image_uri = info.images.first&.uri
      labels = info.labels.map(&:name)
      track_number = 0
      tracks = info.tracklist.map do |entry|
        track_number += 1
        Track.new(
          number: track_number,
          label: entry.position,
          title: entry.title,
          description: '',
        )
      end

      Album.new(
        serial: info.labels.first.catno,
        artist: all_artists.first,
        title: info.title,
        year: info.year,
        genres: info.genres,
        discogs_url: url,
        tracks: tracks,
        all_artists: all_artists,
        labels: labels,
        cover_image_path: cover_image_path(image_uri, release),
      )
    end

    def fetch_file(release)
      path = release_path(release)
      if File.exist?(release)
        data = nil
        File.open(release) do |f|
          data = Marshal.load(f.read)
        end
      else
        nil
      end
    end

    def fetch_discogs(release)
      info = discogs.get_release release
      File.open(release_path(release), 'w') do |f|
        f.write Marshal.dump(info)
      end
      info
    end

    def release_path(release)
      File.join(path, "#{release}.bin")
    end

    def cover_image_path(image_uri, release)
      return nil unless image_uri

      ext = image_uri.split('.').last
      image_path = File.join path, "cover.#{ext}"

      return image_path if File.exist? image_path

      URI.open(image_uri) do |image|
        File.open(image_path, 'w') do |f|
          f.write image.read
        end
      end

      return image_path
    end
  end
end