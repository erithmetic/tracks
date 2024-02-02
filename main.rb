require 'concurrent'
require 'fileutils'
require 'gli'
require 'open3'

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
      track_source_path = File.join(album.source_path, track.number.to_s) + '.wav'

      next unless File.exist? track_source_path

      track_dest_path = File.join(album.dest_path, track.filename) + '.wav'

      highpass_vinyl_track track_source_path
      amplify_vinyl_track track_source_path
      write_vinyl_track track_source_path, track_dest_path
    end
  end
end

def highpass_vinyl_track(track_source_path)
  puts "Highpass filter #{track_source_path}"
  tmp_path = "#{track_source_path}.tmp.wav"
  ffmpeg "-i \"#{track_source_path}\" -af highpass=20 \"#{tmp_path}\""
  FileUtils.mv tmp_path, track_source_path
end

def amplify_vinyl_track(track_source_path)
  out = ffmpeg "-i \"#{track_source_path}\" -filter:a volumedetect -f null /dev/null"

  current_volume = out.match(/max_volume: (-?\d+\.\d+)/)[1].to_f
  adjustment = if current_volume == MAX_VOLUME
                 0
               elsif current_volume < MAX_VOLUME
                 current_volume.abs - MAX_VOLUME.abs
               else
                 -1 * current_volume + MAX_VOLUME
               end

  if adjustment == 0.0
    puts "Not amplifying #{track_source_path}"
  else
    puts "Amplifying #{track_source_path} by #{adjustment}dB"
    tmp_path = "#{track_source_path}.tmp.wav"
    ffmpeg "-i \"#{track_source_path}\" -filter:a \"volume=#{adjustment}dB\" \"#{tmp_path}\""
    FileUtils.mv tmp_path, track_source_path
  end
end

def write_vinyl_track(track_source_path, track_dest_path)
  FileUtils.mkdir_p File.dirname(track_dest_path)

  puts "#{track_source_path} => #{track_dest_path}"
  FileUtils.cp track_source_path, track_dest_path
end

def reset
  clean
  init
end

def ffmpeg(cmd)
  _, out, status = Open3.capture3 "ffmpeg #{cmd}"
  raise "Command failed: ffmpeg #{cmd}\n#{out}" unless status == 0
  return out
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
