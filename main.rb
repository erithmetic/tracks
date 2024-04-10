require 'bundler/setup'

require 'discogs-wrapper'
require 'dotenv/load'
require 'fileutils'
require 'gli'

require_relative './lib/config'
require_relative './lib/beats'
require_relative './lib/beats/library'

class App
  extend GLI::App

  program_desc 'tracks'

  def self.app
    new
  end

  command :vinyl do |c|
    c.action do
      app.process_vinyl
    end
  end

  command :clean do |c|
    c.action do
      app.clean
    end
  end

  command :flacs do |c|
    c.action do
      app.process_flacs
    end
  end

  command :all do |c|
    c.action do 
      app.all
    end
  end

  def library
    @library ||= Beats::Library.load
  end

  def init
    process_vinyl
    copy_aiffs
    copy_mp3s
    process_flacs
  end

  def copy_file(src)
    filename = File.basename src
    dest = File.join(TRACKS_PATH, filename)
    puts "#{src} => #{dest}"
    FileUtils.cp src, dest
  end

  def clean
    Dir.glob("#{TRACKS_PATH}/**/*").each do |f|
      puts "rm -f #{f}"
      FileUtils.rm_rf f
    end
  end

  def copy_aiffs
    puts "COPYING AIFFs"
    Dir.glob("#{DIGITAL_PATH}/**/*.aiff").each { |src| copy_file src }
    puts ""
  end

  def copy_mp3s
    puts "COPYING MP3s"
    Dir.glob("#{DIGITAL_PATH}/**/*.mp3").each { |src| copy_file src }
    puts ""
  end

  def process_flacs
    Beats.each_flac do |path|
      converter = Beats::FlacConversion.from_file library: library, path: path
      if converter.process!
        puts "#{converter.dest_file.album.title} - #{converter.dest_file.track.label}..."
      end
    end
  end

  def process_vinyl
    Beats.each_vinyl_track do |vinyl|
      next unless File.exist? vinyl.source_path
      puts "#{vinyl.album.title} - #{vinyl.track.title}..."
      vinyl.process!
    end
  end

  def all
    clean
    init
  end
end

def main
  exit App.run(ARGV)
end

main
