require 'json'
require 'open3'

require_relative './metadata'
require_relative './track_file'

module Beats
  module FFMPEG
    def self.process(params)
      execute 'ffmpeg', params
    end

    def self.probe(params)
      `ffprobe #{params}`
    end

    def self.execute(cmd, params)
      _, out, status = Open3.capture3 "#{cmd} #{params}"
      raise "Command failed: ffmpeg #{params}\n#{out}" if status != 0
      return out
    end

    def self.apply!(path, cmd)
      path_parts = path.split('.')
      ext = path_parts.pop
      tmp_path = (path_parts + ['tmp', ext]).join('.')
      full_cmd = "-i \"#{path}\" #{cmd} \"#{tmp_path}\""
      result = nil
      begin
        result = execute full_cmd
      rescue Exception => e
        FileUtils.rm_f tmp_path
        raise e
      end
      puts result if ENV['DEBUG'] == 'true'
      FileUtils.mv tmp_path, path
    end

    def self.write_id3!(path, metadata)
      metadata_commands = metadata.to_ffmpeg_metadata.inject("") do |list, (key, value)|
        list = list + "-metadata #{key}=\"#{value.to_s.gsub(/"/,"\\\"")}\" "
      end

      FFMPEG.apply! path, "#{metadata_commands} -id3v2_version 3 -write_id3v2 1"
    end

    def self.write_cover_image!(path, cover_image_path)
      if cover_image_path && File.exist?(cover_image_path)
        FFMPEG.apply! path, "-i \"#{cover_image_path}\"  -c copy -map 0 -map 1 -id3v2_version 3 -write_id3v2 1"
      end
    end

    def self.info(path)
      json = probe "-loglevel error -show_entries stream_tags:format_tags -of json \"#{path}\""
      Metadata.from_from_ffprobe JSON.parse(json)
    end
  end
end
 
