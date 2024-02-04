module Beats
  module FFMPEG
    def self.execute(cmd)
      _, out, status = Open3.capture3 "ffmpeg #{cmd}"
      raise "Command failed: ffmpeg #{cmd}\n#{out}" unless status == 0
      return out
    end

    def self.apply!(path, cmd)
      path_parts = path.split('.')
      ext = path_parts.pop
      tmp_path = (path_parts + ['tmp', ext]).join('.')
      full_cmd = "-i \"#{path}\" #{cmd} \"#{tmp_path}\""
      execute full_cmd
      FileUtils.mv tmp_path, path
    end
  end
end
