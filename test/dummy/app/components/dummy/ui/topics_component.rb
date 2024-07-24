# frozen_string_literal: true

class Dummy::Ui::TopicsComponent < ApplicationComponent
  bem_class_name :centered, :small

  def initialize(topics:, centered: false, small: false)
    @topics = topics
    @centered = centered
    @small = small
  end
end
