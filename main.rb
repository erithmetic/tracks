require 'bundler/setup'

require 'discogs-wrapper'
require 'dotenv/load'
require 'fileutils'
require 'gli'

require_relative './lib/config'
require_relative './lib/beats'
require_relative './lib/beats/destination_track_file'
require_relative './lib/beats/flac_conversion'
require_relative './lib/beats/library'
require_relative './lib/beats/track_file'
require_relative './lib/beats/vinyl_conversion'
require_relative './lib/beats/wav_conversion'

class App
  extend GLI::App

  program_desc 'tracks'

  def self.app
    @app ||= new
  end
  
  command :vinyl do |c|
    c.switch %i{f force}, default_value: false
    c.flag %i{s source_path}, default_value: VINYL_PATH, type: String
    c.action do |_, options|
      app.process_vinyl force: options[:force], source_path: options[:source_path]
    end
  end

  command :export do |c|
    c.action do
      app.process_flacs
      app.process_aiffs
      app.process_mp3s
      app.process_wavs
    end
  end

  def library
    @library ||= Beats::Library.load
  end

  def copy_file(path)
    filename = File.basename path
    dest = File.join(TRACKS_PATH, filename)
    source_file = Beats::TrackFile.read library: library, path: path
    dest_file = Beats::DestinationTrackFile.new album: source_file.album, track: source_file.track, ext: source_file.ext
    return if dest_file.exist?
    dest_file.ensure_dest_path!
    puts "#{source_file.path} => #{dest_file.path}"
    FileUtils.cp source_file.path, dest_file.path
    dest_file.write_metadata! unless dest_file.album.serial.nil?
  end

  def process_aiffs
    Dir.glob("#{DIGITAL_PATH}/**/*.aiff").each { |path| copy_file path }
  end

  def process_mp3s
    Dir.glob("#{DIGITAL_PATH}/**/*.mp3").each { |path| copy_file path }
  end

  def process_flacs
    Beats.each_flac do |path|
      converter = Beats::FlacConversion.from_file library: library, path: path
      if converter.process!
        puts "#{converter.dest_file.album.title} - #{converter.dest_file.track.label}..."
      end
    end
  end

  def process_wavs
    Beats.each_wav do |path|
      converter = Beats::WavConversion.from_file library: library, path: path
      if converter.process!
        puts "#{converter.dest_file.album.title} - #{converter.dest_file.track.label}..."
      end
    end
  end

  def process_vinyl(source_path:, force: false)
    Beats.each_vinyl_track(source_path) do |catalog_number, track_number, path|
      converter = Beats::VinylConversion.from_file(
        library: library,
        catalog_number: catalog_number,
        track_number: track_number,
        path: path
      )

      if converter.process! force: force
        puts "#{catalog_number} - #{converter.album.title} - #{converter.track.title}..."
      end
    end
  end
end

exit App.run(ARGV)
