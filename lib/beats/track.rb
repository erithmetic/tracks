module Beats
  class Track
    attr_reader :number, :label, :description

    def initialize(number:, label:, description:)
      @number = number
      @label = label
      @description = description
    end
  end
end
