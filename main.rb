require 'concurrent'
require 'discogs-wrapper'
require 'dotenv/load'
require 'fileutils'
require 'gli'
require 'open3'

require_relative './lib/config'
require_relative './lib/beats'

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
  Dir.glob("#{ALBUMS_PATH}/**/*.aiff").each { |src| copy_file src }
  puts ""
end

def copy_mp3s
  puts "COPYING MP3s"
  Dir.glob("#{ALBUMS_PATH}/**/*.mp3").each { |src| copy_file src }
  puts ""
end

def process_flacs
  Beats.each_flac do |flac|
    puts "#{flac.source_path} => #{flac.dest_path}"
    flac.convert!
  end
end

def process_vinyl
  Beats.each_vinyl_track do |vinyl|
    next unless File.exist? vinyl.source_path

    vinyl.init

    puts "#{vinyl.album.title} - #{vinyl.track_title}"

    print "HPF + Amplify..."
    old_volume, new_volume = vinyl.apply_hpf_and_amplify!
    puts "#{old_volume}dB => #{new_volume}dB done!"

    print "Tag..."
    vinyl.tag!
    puts "done!"
    
    puts "cp #{vinyl.finalized_path} => #{vinyl.dest_path}"
    vinyl.insert_into_library!
  end
end

def all
  clean
  init
end

class App
  extend GLI::App

  program_desc 'tracks'

  command :vinyl do |c|
    c.action do
      process_vinyl
    end
  end

  command :clean do |c|
    c.action do
      clean
    end
  end

  command :flacs do |c|
    c.action do
      process_flacs
    end
  end

  command :all do |c|
    c.action do 
      all
    end
  end
end

def main
  exit App.run(ARGV)
end

main
