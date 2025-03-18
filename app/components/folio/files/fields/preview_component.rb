# frozen_string_literal: true

class Folio::Files::Fields::PreviewComponent < ApplicationComponent
  def initialize(f:)
    @f = f
    @human_type = f.object.class.human_type
  end

  def render?
    @human_type.in?(%w[image video audio])
  end
end
