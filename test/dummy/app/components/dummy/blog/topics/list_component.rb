# frozen_string_literal: true

class Dummy::Blog::Topics::ListComponent < ApplicationComponent
  MAX_ITEMS_UNCOLLAPSED_MOBILE = 6
  MAX_ITEMS_UNCOLLAPSED_DESKTOP = 20

  def initialize(topics:)
    @topics = topics
  end
end
