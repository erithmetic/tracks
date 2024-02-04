module Beats
  class Track
    attr_reader :number, :label, :description

    def initialize(number:, label:, description:)
      @number = number
      @label = label
      @description = description
    end

    def filename
      [number, label].join(' - ')
    end
  end
end
