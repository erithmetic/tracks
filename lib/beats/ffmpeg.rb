require 'json'
require 'open3'
require 'shellwords'

require_relative './metadata'
require_relative './track_file'

module Beats
  module FFMPEG
    def self.probe(path, params)
      `ffprobe #{params} #{Shellwords.escape(path)}`
    end

    def self.execute(input_path, params, output_path = nil)
      cmd = "-i #{Shellwords.escape(input_path)} #{params}"
      output_path ||= "/dev/null"
      cmd += " #{Shellwords.escape(output_path)}" unless output_path.nil?

      _, out, status = Open3.capture3 "ffmpeg #{cmd}"

      raise "Command failed: ffmpeg #{cmd}\n#{out}" if status != 0
      return out
    end

    def self.modify!(input_path, params)
      path_parts = input_path.split('.')
      ext = path_parts.pop
      tmp_path = (path_parts + ['tmp', ext]).join('.')
      result = nil
      begin
        result = execute input_path, params, tmp_path
      rescue Exception => e
        FileUtils.rm_f tmp_path
        raise e
      end

      puts result if ENV['DEBUG'] == 'true'
      FileUtils.mv tmp_path, input_path, force: true
    end

    def self.write_id3!(path, metadata)
      metadata_commands = metadata.to_ffmpeg_metadata.inject("") do |list, (key, value)|
        list = list + "-metadata #{key}=\"#{value.to_s.gsub(/"/,"\\\"")}\" "
      end

      FFMPEG.modify! path, "-c:a pcm_s24be -ar 44100 #{metadata_commands} -id3v2_version 3 -write_id3v2 1"
    end

    def self.write_mp3_id3!(path, metadata)
      metadata_commands = metadata.to_ffmpeg_metadata.inject("") do |list, (key, value)|
        list = list + "-metadata #{key}=\"#{value.to_s.gsub(/"/,"\\\"")}\" "
      end

      FFMPEG.modify! path, "#{metadata_commands} -id3v2_version 3 -write_id3v2 1"
    end

    def self.write_cover_image!(path, cover_image_path)
      if cover_image_path && File.exist?(cover_image_path)
        FFMPEG.modify! path, "-i \"#{cover_image_path}\" -c copy -map 0 -map 1 -id3v2_version 3 -write_id3v2 1"
      end
    end

    def self.info(path)
      json = probe path, "-loglevel error -show_entries stream_tags:format_tags -of json"
      Metadata.from_ffprobe JSON.parse(json)
    end
  end
end
 
