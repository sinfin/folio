# frozen_string_literal: true

class Dummy::Ui::ChipsComponent < ApplicationComponent
  bem_class_name :small, :large

  def initialize(links:, small: false, large: false)
    @links = links
    @small = small
    @large = large
  end

  def ul_class_name
    if @small
      "fs-text-xs"
    elsif @large
      "fs-text-m"
    else
      "fs-text-s"
    end
  end
end
