require 'concurrent'
require 'fileutils'
require 'gli'

require_relative './lib/config'
require_relative './lib/beats'

# pool = Concurrent::ThreadPoolExecutor.new(
#   min_threads: [2, Concurrent.processor_count].max,
#   max_threads: [2, Concurrent.processor_count].max,
#   fallback_policy: :caller_runs
# )
# futures = []

def init
  copy_aiffs
  copy_mp3s
  convert_root_flacs
  convert_album_flacs
end

def copy_file(src)
  filename = File.basename src
  dest = File.join(TRACKS_PATH, filename)
  puts "#{src} => #{dest}"
  FileUtils.cp src, dest
end

def convert_file(src, dest_dir)
  filename = File.basename src, '.flac'
  dest = File.join(dest_dir, "#{filename}.wav")
  cmd = "ffmpeg -y -i \"#{src}\" -c:a pcm_s24le -c:v copy \"#{dest}\""
  result =  system cmd, [:out, :err] => "/dev/null"
  raise "Failed to convert #{src}" unless result
  puts "#{src} => #{dest}"
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

def convert_root_flacs
  puts "CONVERTING ROOT FLACs"
  Dir.glob("#{ALBUMS_PATH}/*.flac").each do |src|
    convert_file src, TRACKS_PATH
  end
  puts ""
end

def convert_album_flacs
  puts "CONVERTING ALBUM FLACs"
  Dir.glob("#{ALBUMS_PATH}/*").each do |f|
    if File.directory?(f)
      Dir.glob("#{f}/*.flac").each do |flac|
        dest_dir = File.join(TRACKS_PATH, File.basename(f))
        Dir.mkdir dest_dir rescue nil
        convert_file flac, dest_dir
      end
    end
  end
  puts ""
end

def vinyl
  Beats.each_album do |album|
    album.tracks.each do |track|
      write_vinyl_track album, track
    end
  end
end

def write_vinyl_track(album, track)
  track_source_path = File.join(album.source_path, track.number.to_s) + '.wav'
  track_dest_path = File.join(album.dest_path, track.filename) + '.wav'

  if File.exist?(track_source_path)
    FileUtils.mkdir_p File.dirname(track_dest_path)

    puts "#{track_source_path} => #{track_dest_path}"
    FileUtils.cp track_source_path, track_dest_path
  end
end

def reset
  clean
  init
end

class App
  extend GLI::App

  program_desc 'tracks'

  command :vinyl do |c|
    c.action do
      vinyl
    end
  end

  command :clean do |c|
    c.action do
      clean
    end
  end

  command :flacs do |c|
    c.action do
      convert_root_flacs
      convert_album_flacs
    end
  end

  command :reset do |c|
    c.action do 
      reset
    end
  end
end

def main
  exit App.run(ARGV)
end

main

# while futures.any?(-> (f) { f.incomplete? }) do
#   putc '.'
# end
