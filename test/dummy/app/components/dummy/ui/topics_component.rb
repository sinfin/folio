# frozen_string_literal: true

class Dummy::Ui::TopicsComponent < ApplicationComponent
  MAX_ITEMS_UNCOLLAPSED_MOBILE = 6
  MAX_ITEMS_UNCOLLAPSED_DESKTOP = 20

  bem_class_name :centered, :small, :collapsible_mobile, :collapsible_desktop

  def initialize(topics:, centered: false, small: false, collapsible: false)
    @topics = topics
    @centered = centered
    @small = small
    @collapsible = collapsible
    @collapsible_mobile = collapsible && @topics.size >= MAX_ITEMS_UNCOLLAPSED_MOBILE + 1
    @collapsible_desktop = collapsible && @topics.size >= MAX_ITEMS_UNCOLLAPSED_DESKTOP + 1
  end
end
