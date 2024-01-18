require 'concurrent'
require 'fileutils'
require 'gli'

ALBUM_DIR="#{ENV['HOME']}/Music/Albums"
TRACK_DIR="#{ENV['HOME']}/Music/Tracks"

# pool = Concurrent::ThreadPoolExecutor.new(
#   min_threads: [2, Concurrent.processor_count].max,
#   max_threads: [2, Concurrent.processor_count].max,
#   fallback_policy: :caller_runs
# )
# futures = []


def copy_file(src)
  filename = File.basename src
  dest = File.join(TRACK_DIR, filename)
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
  Dir.glob("#{TRACK_DIR}/**/*").each do |f|
    puts "rm -f #{f}"
    FileUtils.rm_rf f
  end
end

def copy_aiffs
  puts "COPYING AIFFs"
  Dir.glob("#{ALBUM_DIR}/**/*.aiff").each { |src| copy_file src }
  puts ""
end

def copy_mp3s
  puts "COPYING MP3s"
  Dir.glob("#{ALBUM_DIR}/**/*.mp3").each { |src| copy_file src }
  puts ""
end

def convert_root_flacs
  puts "CONVERTING ROOT FLACs"
  Dir.glob("#{ALBUM_DIR}/*.flac").each do |src|
    convert_file src, TRACK_DIR
  end
  puts ""
end

def convert_album_flacs
  puts "CONVERTING ALBUM FLACs"
  Dir.glob("#{ALBUM_DIR}/*").each do |f|
    if File.directory?(f)
      Dir.glob("#{f}/*.flac").each do |flac|
        dest_dir = File.join(TRACK_DIR, File.basename(f))
        Dir.mkdir dest_dir rescue nil
        convert_file flac, dest_dir
      end
    end
  end
  puts ""
end

def generate_vinyl_stubs

end

def init
  copy_aiffs
  copy_mp3s
  convert_root_flacs
  convert_album_flacs
end

def reset
  clean
  init
end

class App
  extend GLI::App

  program_desc 'tracks'

  command :generate_vinyl_stubs do |c|
    c.action do
      generate_vinyl_stubs
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