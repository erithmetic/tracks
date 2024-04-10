require 'open3'

require_relative './track_file'

module Beats
  module FFMPEG
    def self.execute(cmd, allow_error: false)
      _, out, status = Open3.capture3 "ffmpeg #{cmd}"
      raise "Command failed: ffmpeg #{cmd}\n#{out}" if status != 0 && !allow_error
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
      # cover_image_command = if cover_image_path
      #   "-i \"#{cover_image_path}\"  -c copy -map 0 -map 1"
      # end

      metadata_commands = metadata.inject("") do |list, (key, value)|
        list = list + "-metadata #{key}=\"#{value}\" "
      end

      FFMPEG.apply! path, "#{metadata_commands} -id3v2_version 3 -write_id3v2 1"
    end

    def self.write_cover_image!(path, cover_image_path)
      if cover_image_path && File.exist?(cover_image_path)
        FFMPEG.apply! path, "-i \"#{cover_image_path}\"  -c copy -map 0 -map 1 -id3v2_version 3 -write_id3v2 1"
      end
    end

    def self.info(path)
      raw = execute "-i \"#{path}\"", allow_error: true
      metadata = {}

      current_key = nil
      raw.lines.each do |line|
        return metadata if line =~ /Stream #\d/

        matches = line.match(/([^:]*):\s(.+)/)
        next if matches.nil?

        value = matches[2]
        if key = matches[1]
          stripped_key = key.strip.to_sym
          if Beats::TrackFile::METADATA_KEYS.include?(stripped_key)
            current_key = stripped_key
            metadata[current_key] = ''
          else
            current_key = nil
          end
        end

        metadata[current_key] += value unless current_key.nil?
      end

      metadata
    end
  end
end
 
