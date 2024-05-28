# frozen_string_literal: true

class Dummy::Ui::VideoComponent < ApplicationComponent
  bem_class_name :cover, :aspect_ratio

  def initialize(video:, aspect_ratio: nil, thumb_size: nil, cover: false)
    @video = video
    @thumb_size = thumb_size
    @cover = cover
    @aspect_ratio = aspect_ratio
    @has_aspect_ratio = !!aspect_ratio
  end

  def render?
    @video.present?
  end

  def spacer_tag
    return {} unless @aspect_ratio

    {
      tag: :div,
      class: "d-ui-video__spacer",
      style: "padding-top: #{100.0 / @aspect_ratio}%",
    }
  end
end
