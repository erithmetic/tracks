module Beats
  class Track
    attr_reader :number, :label, :description, :album, :title
    attr_writer :album

    def self.from_file(album:, source_path:)
      new number: nil, label: nil, description: nil
    end

    def initialize(number:, label:, description:, title:, album: nil)
      @album = album
      @number = number.to_i
      @label = label
      @title = title
      @description = description || ''
    end

    def merge(other)
      self.class.new(
        number: number || other.number,
        label: label || other.label,
        description: [description, other.description].compact.join("\n"),
        title: title || other.title,
        album: album || other.album,
      )
    end
  end
end
