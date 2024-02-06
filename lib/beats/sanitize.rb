module Beats
  module Sanitize
    def self.filename(file)
      file.gsub /[\/"'\$\%\&\*\(\)]/, ''
    end
  end
end